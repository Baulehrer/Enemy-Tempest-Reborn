#!/usr/bin/env python3
"""Build an AROS diagnostic ADF: CloseWindow NOP plus visible startup errors."""

from __future__ import annotations

import hashlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

SOURCE_ADF = ROOT / "work/kickstart-deps/patches/closewb-nop/ENEMY1_V2_DE_A.closewb-nop.adf"
SOURCE_CONFIG = ROOT / "configs/fs-uae/enemy1_arosclosewbnop_a500.fs-uae"
OUT_DIR = ROOT / "work/kickstart-deps/patches/closewb-nop-diag"
PATCHED_ADF = OUT_DIR / "ENEMY1_V2_DE_A.closewb-nop-diag.adf"
PATCHED_CONFIG = ROOT / "configs/fs-uae/enemy1_arosclosewbnopdiag_a500.fs-uae"
MANIFEST = OUT_DIR / "manifest.txt"

ORIGINAL = (
    b"ENEMY_A:enif/enintro  >nil:\n"
    b"ENEMY_A:c/closewb\n"
    b"ENEMY_A:ef/enemy >nil:\n"
)
PATCHED = (
    b"ENEMY_A:enif/enintro\n"
    b"why\n"
    b"ENEMY_A:c/closewb\n"
    b"why\n"
    b"ENEMY_A:ef/enemy\n"
    b"why\n"
    b"\n"
)
BLOCK_SIZE = 512
CHECKSUM_WORD_INDEX = 5


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_be32(data: bytes | bytearray, offset: int) -> int:
    return int.from_bytes(data[offset : offset + 4], "big")


def write_be32(data: bytearray, offset: int, value: int) -> None:
    data[offset : offset + 4] = value.to_bytes(4, "big")


def fix_amigados_block_checksum(data: bytearray, block_offset: int) -> tuple[int, int]:
    checksum_offset = block_offset + CHECKSUM_WORD_INDEX * 4
    old_checksum = read_be32(data, checksum_offset)
    write_be32(data, checksum_offset, 0)
    total = 0
    for offset in range(block_offset, block_offset + BLOCK_SIZE, 4):
        total = (total + read_be32(data, offset)) & 0xFFFFFFFF
    new_checksum = (-total) & 0xFFFFFFFF
    write_be32(data, checksum_offset, new_checksum)
    verify = 0
    for offset in range(block_offset, block_offset + BLOCK_SIZE, 4):
        verify = (verify + read_be32(data, offset)) & 0xFFFFFFFF
    if verify != 0:
        raise SystemExit(f"Checksum verification failed for block 0x{block_offset:x}")
    return old_checksum, new_checksum


def main() -> int:
    if len(PATCHED) != len(ORIGINAL):
        raise SystemExit(f"replacement length mismatch: {len(PATCHED)} != {len(ORIGINAL)}")

    source = SOURCE_ADF.read_bytes()
    hits: list[int] = []
    start = 0
    while True:
        pos = source.find(ORIGINAL, start)
        if pos < 0:
            break
        hits.append(pos)
        start = pos + 1
    if len(hits) != 1:
        raise SystemExit(f"startup-sequence signature not unique: {hits!r}")

    patched = bytearray(source)
    offset = hits[0]
    patched[offset : offset + len(PATCHED)] = PATCHED
    block_offset = (offset // BLOCK_SIZE) * BLOCK_SIZE
    old_checksum, new_checksum = fix_amigados_block_checksum(patched, block_offset)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    PATCHED_ADF.write_bytes(patched)

    config = SOURCE_CONFIG.read_text(encoding="utf-8")
    config = config.replace(str(SOURCE_ADF), str(PATCHED_ADF))
    config = config.replace("enemy1_arosclosewbnop_a500_", "enemy1_arosclosewbnopdiag_a500_")
    config = config.replace("enemy1_arosclosewbnop_a500.log", "enemy1_arosclosewbnopdiag_a500.log")
    PATCHED_CONFIG.write_text(config, encoding="utf-8")

    MANIFEST.write_text(
        "\n".join(
            [
                "patch=enemy1-closewb-nop-diag",
                f"source_adf={SOURCE_ADF}",
                f"source_sha256={sha256(source)}",
                f"patched_adf={PATCHED_ADF}",
                f"patched_sha256={sha256(bytes(patched))}",
                f"patched_config={PATCHED_CONFIG}",
                f"startup_offset=0x{offset:06x}",
                f"checksum_block_offset=0x{block_offset:06x}",
                f"old_checksum=0x{old_checksum:08x}",
                f"new_checksum=0x{new_checksum:08x}",
                "runtime_effect=show enintro/enemy output and `why` results in AROS shell",
                "",
            ]
        ),
        encoding="utf-8",
    )

    print(PATCHED_ADF)
    print(PATCHED_CONFIG)
    print(MANIFEST)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
