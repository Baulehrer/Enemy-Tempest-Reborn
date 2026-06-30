#!/usr/bin/env python3
"""Build a reproducible Enemy 1 ADF/config variant skipping the closewb call.

The patch changes the unique startup sequence:

    0006C430 TST.L  (A0,$0034)
    0006C436 BEQ.B  0006C446

to:

    0006C436 BRA.B  0006C446

This preserves the existing branch target and skips the Workbench/ActiveWindow
CloseWindow path without modifying the original ADF or any Kickstart ROM.
"""

from __future__ import annotations

import hashlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

SOURCE_ADF = ROOT / "assets/adf/ENEMY1_V2_DE_A.adf"
SOURCE_CONFIG = ROOT / "configs/fs-uae/enemy1_aros_a500.fs-uae"

OUT_DIR = ROOT / "work/kickstart-deps/patches/closewb-skip"
PATCHED_ADF = OUT_DIR / "ENEMY1_V2_DE_A.closewb-skip.adf"
PATCHED_CONFIG = ROOT / "configs/fs-uae/enemy1_arosclosewbskip_a500.fs-uae"
MANIFEST = OUT_DIR / "manifest.txt"

EXPECTED_SHA256 = "f8a970e7225541c34d2322875df8294a73604afbab679d0ecb002a5ac01cc28e"
PATCH_OFFSET = 0x5305E
ORIGINAL = bytes.fromhex("670e")
PATCHED = bytes.fromhex("600e")
BLOCK_SIZE = 512
CHECKSUM_WORD_INDEX = 5

SIGNATURE_OFFSET = 0x53042
SIGNATURE = bytes.fromhex(
    "4e55000042a7486c80024eba06e22940801e206c801e4aa80034"
    "504f670e206c801e2f2800344eba0718584f4eba071e"
)


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
    source = SOURCE_ADF.read_bytes()
    source_hash = sha256(source)
    if source_hash != EXPECTED_SHA256:
        raise SystemExit(
            f"Unexpected source ADF hash for {SOURCE_ADF}: {source_hash}"
        )

    hits = []
    start = 0
    while True:
        pos = source.find(SIGNATURE, start)
        if pos < 0:
            break
        hits.append(pos)
        start = pos + 1
    if hits != [SIGNATURE_OFFSET]:
        raise SystemExit(f"Signature is not unique at expected offset: {hits!r}")

    old = source[PATCH_OFFSET : PATCH_OFFSET + len(ORIGINAL)]
    if old != ORIGINAL:
        raise SystemExit(
            f"Patch bytes mismatch at 0x{PATCH_OFFSET:x}: "
            f"got {old.hex()}, expected {ORIGINAL.hex()}"
        )

    patched = bytearray(source)
    patched[PATCH_OFFSET : PATCH_OFFSET + len(PATCHED)] = PATCHED
    block_offset = (PATCH_OFFSET // BLOCK_SIZE) * BLOCK_SIZE
    old_checksum, new_checksum = fix_amigados_block_checksum(patched, block_offset)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    PATCHED_ADF.write_bytes(patched)

    config = SOURCE_CONFIG.read_text(encoding="utf-8")
    config = config.replace(str(SOURCE_ADF), str(PATCHED_ADF))
    config = config.replace("enemy1_aros_a500_", "enemy1_arosclosewbskip_a500_")
    config = config.replace("enemy1_aros_a500.log", "enemy1_arosclosewbskip_a500.log")
    PATCHED_CONFIG.write_text(config, encoding="utf-8")

    manifest = "\n".join(
        [
            "patch=enemy1-closewb-skip",
            f"source_adf={SOURCE_ADF}",
            f"source_sha256={source_hash}",
            f"patched_adf={PATCHED_ADF}",
            f"patched_sha256={sha256(bytes(patched))}",
            f"patched_config={PATCHED_CONFIG}",
            f"signature_offset=0x{SIGNATURE_OFFSET:06x}",
            f"checksum_block_offset=0x{block_offset:06x}",
            f"old_checksum=0x{old_checksum:08x}",
            f"new_checksum=0x{new_checksum:08x}",
            f"patch_offset=0x{PATCH_OFFSET:06x}",
            f"original_bytes={ORIGINAL.hex()}",
            f"patched_bytes={PATCHED.hex()}",
            "runtime_effect=0006C436 BEQ.B 0006C446 -> BRA.B 0006C446",
            "",
        ]
    )
    MANIFEST.write_text(manifest, encoding="utf-8")

    print(PATCHED_ADF)
    print(PATCHED_CONFIG)
    print(MANIFEST)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
