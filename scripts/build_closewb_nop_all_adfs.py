#!/usr/bin/env python3
"""Build closewb-NOP ADF variants for all Enemy A disks.

The patch replaces the single JSR CloseWindow instruction in c/closewb with
two 68k NOPs. Original ADFs are left untouched; patched images and manifests
are written under work/kickstart-deps/patches/closewb-nop-all/.
"""

from __future__ import annotations

import hashlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets/adf"
OUT_DIR = ROOT / "work/kickstart-deps/patches/closewb-nop-all"

SOURCE_ADFS = [
    "ENEMY1_V2_DE_A.adf",
    "ENEMY1_V2_EN_A.adf",
    "ENEMY2_V2_DE_A.adf",
    "ENEMY2_V2_EN_A.adf",
]

EXPECTED_SHA256 = {
    "ENEMY1_V2_DE_A.adf": "f8a970e7225541c34d2322875df8294a73604afbab679d0ecb002a5ac01cc28e",
    "ENEMY1_V2_EN_A.adf": "358118e0352af731423278f8a9eb927a027f23357c57e3c303a2e8c5bac9daca",
    "ENEMY2_V2_DE_A.adf": "7639e8100cc7525d6f38c9343955b74f23e6666ca1de76c61803fb06cf767724",
    "ENEMY2_V2_EN_A.adf": "6c6a5bad08dbd6672689627f4461890fefa08eb5a3bf45edb5fc30d22625f4bc",
}

SIGNATURE_OFFSET = 0x53042
PATCH_OFFSET = 0x53068
ORIGINAL = bytes.fromhex("4eba0718")
PATCHED = bytes.fromhex("4e714e71")
BLOCK_SIZE = 512
CHECKSUM_WORD_INDEX = 5

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


def find_all(data: bytes, needle: bytes) -> list[int]:
    hits: list[int] = []
    start = 0
    while True:
        pos = data.find(needle, start)
        if pos < 0:
            return hits
        hits.append(pos)
        start = pos + 1


def patch_adf(source_adf: Path) -> tuple[Path, str]:
    source = source_adf.read_bytes()
    source_hash = sha256(source)
    expected_hash = EXPECTED_SHA256[source_adf.name]
    if source_hash != expected_hash:
        raise SystemExit(
            f"Unexpected source ADF hash for {source_adf}: "
            f"{source_hash}, expected {expected_hash}"
        )

    hits = find_all(source, SIGNATURE)
    if hits != [SIGNATURE_OFFSET]:
        raise SystemExit(f"Signature is not unique at expected offset in {source_adf}: {hits!r}")

    old = source[PATCH_OFFSET : PATCH_OFFSET + len(ORIGINAL)]
    if old != ORIGINAL:
        raise SystemExit(
            f"Patch bytes mismatch in {source_adf} at 0x{PATCH_OFFSET:x}: "
            f"got {old.hex()}, expected {ORIGINAL.hex()}"
        )

    patched = bytearray(source)
    patched[PATCH_OFFSET : PATCH_OFFSET + len(PATCHED)] = PATCHED
    block_offset = (PATCH_OFFSET // BLOCK_SIZE) * BLOCK_SIZE
    old_checksum, new_checksum = fix_amigados_block_checksum(patched, block_offset)

    patched_adf = OUT_DIR / f"{source_adf.stem}.closewb-nop.adf"
    patched_adf.write_bytes(patched)
    patched_hash = sha256(bytes(patched))

    manifest = OUT_DIR / f"{source_adf.stem}.closewb-nop.manifest.txt"
    manifest.write_text(
        "\n".join(
            [
                "patch=closewb-nop",
                f"source_adf={source_adf}",
                f"source_sha256={source_hash}",
                f"patched_adf={patched_adf}",
                f"patched_sha256={patched_hash}",
                f"signature_offset=0x{SIGNATURE_OFFSET:06x}",
                f"checksum_block_offset=0x{block_offset:06x}",
                f"old_checksum=0x{old_checksum:08x}",
                f"new_checksum=0x{new_checksum:08x}",
                f"patch_offset=0x{PATCH_OFFSET:06x}",
                f"original_bytes={ORIGINAL.hex()}",
                f"patched_bytes={PATCHED.hex()}",
                "runtime_effect=JSR CloseWindow -> NOP; NOP in c/closewb",
                "",
            ]
        ),
        encoding="utf-8",
    )
    return patched_adf, patched_hash


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    summary_lines = ["patch_set=closewb-nop-all"]
    for name in SOURCE_ADFS:
        patched_adf, patched_hash = patch_adf(SOURCE_DIR / name)
        summary_lines.append(f"{patched_adf.name}={patched_hash}")
        print(patched_adf)
    (OUT_DIR / "manifest.txt").write_text("\n".join(summary_lines) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
