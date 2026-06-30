#!/usr/bin/env python3
"""Build Enemy 1 boot-split ADFs.

Inputs are the closewb-NOP A disks. Outputs:
- game-nointro: run closewb, then ef/enemy directly
- intro-only: run enintro only, then end the shell script

The original ADFs are not modified.
"""

from __future__ import annotations

import hashlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "work/kickstart-deps/patches/closewb-nop-all"
OUT_DIR = ROOT / "work/kickstart-deps/patches/enemy1-boot-split"

SOURCES = {
    "de": SOURCE_DIR / "ENEMY1_V2_DE_A.closewb-nop.adf",
    "en": SOURCE_DIR / "ENEMY1_V2_EN_A.closewb-nop.adf",
}

EXPECTED_SHA256 = {
    "de": "a685d1c2d3f24ba70a96ed02f7e6385e463e3acf9d285de3e39d68f24597ea75",
    "en": "c5eaa118289428957e313a53415136b9f0eb85dbd38c0f6a89e084274e1b3c12",
}

ORIGINAL = (
    b"ENEMY_A:enif/enintro  >nil:\n"
    b"ENEMY_A:c/closewb\n"
    b"ENEMY_A:ef/enemy >nil:\n"
)

GAME_NOINTERO = (
    b"ENEMY_A:c/closewb\n"
    b"ENEMY_A:ef/enemy >nil:\n"
)

INTRO_ONLY = (
    b"ENEMY_A:enif/enintro\n"
    b"endcli\n"
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


def padded(payload: bytes) -> bytes:
    if len(payload) > len(ORIGINAL):
        raise SystemExit(f"replacement too long: {len(payload)} > {len(ORIGINAL)}")
    return payload + b" " * (len(ORIGINAL) - len(payload))


def find_startup(data: bytes, source: Path) -> int:
    hits: list[int] = []
    start = 0
    while True:
        pos = data.find(ORIGINAL, start)
        if pos < 0:
            break
        hits.append(pos)
        start = pos + 1
    if len(hits) != 1:
        raise SystemExit(f"startup signature not unique in {source}: {hits!r}")
    return hits[0]


def write_variant(lang: str, source: Path, mode: str, replacement: bytes) -> tuple[Path, str]:
    source_data = source.read_bytes()
    source_hash = sha256(source_data)
    if source_hash != EXPECTED_SHA256[lang]:
        raise SystemExit(
            f"Unexpected source hash for {source}: {source_hash}, "
            f"expected {EXPECTED_SHA256[lang]}"
        )

    offset = find_startup(source_data, source)
    patched = bytearray(source_data)
    patched[offset : offset + len(ORIGINAL)] = padded(replacement)
    block_offset = (offset // BLOCK_SIZE) * BLOCK_SIZE
    old_checksum, new_checksum = fix_amigados_block_checksum(patched, block_offset)

    stem = source.name.replace(".closewb-nop.adf", f".{mode}.adf")
    target = OUT_DIR / stem
    target.write_bytes(patched)
    target_hash = sha256(bytes(patched))

    manifest = OUT_DIR / stem.replace(".adf", ".manifest.txt")
    manifest.write_text(
        "\n".join(
            [
                f"patch=enemy1-{mode}",
                f"language={lang}",
                f"source_adf={source}",
                f"source_sha256={source_hash}",
                f"patched_adf={target}",
                f"patched_sha256={target_hash}",
                f"startup_offset=0x{offset:06x}",
                f"checksum_block_offset=0x{block_offset:06x}",
                f"old_checksum=0x{old_checksum:08x}",
                f"new_checksum=0x{new_checksum:08x}",
                f"original_startup={ORIGINAL!r}",
                f"patched_startup={replacement!r}",
                "",
            ]
        ),
        encoding="utf-8",
    )
    return target, target_hash


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    summary = ["patch_set=enemy1-boot-split"]
    for lang, source in SOURCES.items():
        game_target, game_hash = write_variant(lang, source, "game-nointro", GAME_NOINTERO)
        intro_target, intro_hash = write_variant(lang, source, "intro-only", INTRO_ONLY)
        summary.append(f"{game_target.name}={game_hash}")
        summary.append(f"{intro_target.name}={intro_hash}")
        print(game_target)
        print(intro_target)
    (OUT_DIR / "manifest.txt").write_text("\n".join(summary) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
