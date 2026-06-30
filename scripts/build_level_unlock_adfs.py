#!/usr/bin/env python3
"""Build Enemy ADF variants with all levels selectable but level 1 shown.

This mirrors the proven Enemy CD32 patches:
- file offset 0x106: moveq #1,d0; nop (default shown level = 1)
- file offset 0x30b2a: nop; nop (remove cap branch, all levels selectable)
- Enemy 2 only: immediate cap byte 0x22 -> 0x1d (29 levels)

Because the AmigaDOS files are fragmented in the ADFs, this script patches the
verified byte signatures at their disk-image offsets and fixes each touched
AmigaDOS block checksum.
"""

from __future__ import annotations

import hashlib
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "work/kickstart-deps/patches/level-unlock"

DEFAULT_ORIGINAL = bytes.fromhex("0840000033c00000")
DEFAULT_PATCH = bytes.fromhex("70014e7133c00000")
CAP_ORIGINAL = bytes.fromhex("6700000a13fc0022")
CAP_PATCH_E1 = bytes.fromhex("4e714e7113fc0022")
CAP_PATCH_E2 = bytes.fromhex("4e714e7113fc001d")

BLOCK_SIZE = 512
CHECKSUM_WORD_INDEX = 5


@dataclass(frozen=True)
class Target:
    name: str
    source: Path
    expected_sha256: str
    cap_patch: bytes
    expected_default_hits: tuple[int, ...]
    expected_cap_hits: tuple[int, ...]


TARGETS = [
    Target(
        name="enemy1_de",
        source=ROOT / "work/kickstart-deps/patches/enemy1-boot-split/ENEMY1_V2_DE_A.game-nointro.adf",
        expected_sha256="79c79775874065989f400c5e5ad10b3f13e16b3b8d25c3ed5a828d65a07ebf80",
        cap_patch=CAP_PATCH_E1,
        expected_default_hits=(0x0C6D1E,),
        expected_cap_hits=(0x01EB82,),
    ),
    Target(
        name="enemy1_en",
        source=ROOT / "work/kickstart-deps/patches/enemy1-boot-split/ENEMY1_V2_EN_A.game-nointro.adf",
        expected_sha256="08dda1ad4ec5f8740927cf2f7a5a145ad656a5acf0f3ee5d68ba82dacc89f7ed",
        cap_patch=CAP_PATCH_E1,
        expected_default_hits=(0x0C6D1E,),
        expected_cap_hits=(0x01EB82,),
    ),
    Target(
        name="enemy2_de",
        source=ROOT / "work/kickstart-deps/patches/closewb-nop-all/ENEMY2_V2_DE_A.closewb-nop.adf",
        expected_sha256="69cbefa5d2f53d3445903a8caaa730c4c7edfebe48ac310be17d601c9c36f92f",
        cap_patch=CAP_PATCH_E2,
        expected_default_hits=(0x08971E,),
        expected_cap_hits=(0x01E582, 0x0BD582),
    ),
    Target(
        name="enemy2_en",
        source=ROOT / "work/kickstart-deps/patches/closewb-nop-all/ENEMY2_V2_EN_A.closewb-nop.adf",
        expected_sha256="3c1084ca86328ad7a04000d5e59963a475eb600ba8361d308f0d232bf2b2c70b",
        cap_patch=CAP_PATCH_E2,
        expected_default_hits=(0x08971E,),
        expected_cap_hits=(0x01E582, 0x0BD582),
    ),
]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_be32(data: bytes | bytearray, offset: int) -> int:
    return int.from_bytes(data[offset : offset + 4], "big")


def write_be32(data: bytearray, offset: int, value: int) -> None:
    data[offset : offset + 4] = value.to_bytes(4, "big")


def find_all(data: bytes | bytearray, needle: bytes) -> tuple[int, ...]:
    hits: list[int] = []
    start = 0
    while True:
        pos = bytes(data).find(needle, start)
        if pos < 0:
            return tuple(hits)
        hits.append(pos)
        start = pos + 1


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


def apply_patch(data: bytearray, offset: int, original: bytes, patched: bytes) -> None:
    current = bytes(data[offset : offset + len(original)])
    if current != original:
        raise SystemExit(
            f"Patch mismatch at 0x{offset:06x}: got {current.hex()}, expected {original.hex()}"
        )
    data[offset : offset + len(patched)] = patched


def build_target(target: Target) -> tuple[Path, str]:
    source = target.source.read_bytes()
    source_hash = sha256(source)
    if source_hash != target.expected_sha256:
        raise SystemExit(
            f"Unexpected source hash for {target.source}: "
            f"{source_hash}, expected {target.expected_sha256}"
        )

    default_hits = find_all(source, DEFAULT_ORIGINAL)
    cap_hits = find_all(source, CAP_ORIGINAL)
    if default_hits != target.expected_default_hits:
        raise SystemExit(f"{target.name}: default hits {default_hits!r}")
    if cap_hits != target.expected_cap_hits:
        raise SystemExit(f"{target.name}: cap hits {cap_hits!r}")

    patched = bytearray(source)
    touched_blocks: set[int] = set()
    for offset in default_hits:
        apply_patch(patched, offset, DEFAULT_ORIGINAL, DEFAULT_PATCH)
        touched_blocks.add((offset // BLOCK_SIZE) * BLOCK_SIZE)
    for offset in cap_hits:
        apply_patch(patched, offset, CAP_ORIGINAL, target.cap_patch)
        touched_blocks.add((offset // BLOCK_SIZE) * BLOCK_SIZE)

    checksum_lines = []
    for block_offset in sorted(touched_blocks):
        old_checksum, new_checksum = fix_amigados_block_checksum(patched, block_offset)
        checksum_lines.append(
            f"checksum_block=0x{block_offset:06x} old=0x{old_checksum:08x} new=0x{new_checksum:08x}"
        )

    target_path = OUT_DIR / f"{target.source.stem}.level-unlock.adf"
    target_path.write_bytes(patched)
    target_hash = sha256(bytes(patched))

    manifest = OUT_DIR / f"{target.source.stem}.level-unlock.manifest.txt"
    manifest.write_text(
        "\n".join(
            [
                "patch=level-unlock-show-level-1",
                f"target={target.name}",
                f"source_adf={target.source}",
                f"source_sha256={source_hash}",
                f"patched_adf={target_path}",
                f"patched_sha256={target_hash}",
                f"default_offsets={','.join(f'0x{x:06x}' for x in default_hits)}",
                f"default_original={DEFAULT_ORIGINAL.hex()}",
                f"default_patched={DEFAULT_PATCH.hex()}",
                f"cap_offsets={','.join(f'0x{x:06x}' for x in cap_hits)}",
                f"cap_original={CAP_ORIGINAL.hex()}",
                f"cap_patched={target.cap_patch.hex()}",
                *checksum_lines,
                "runtime_effect=show level 1 while allowing highest level selection through normal level control",
                "",
            ]
        ),
        encoding="utf-8",
    )
    return target_path, target_hash


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    summary = ["patch_set=level-unlock-show-level-1"]
    for target in TARGETS:
        patched_adf, patched_hash = build_target(target)
        summary.append(f"{patched_adf.name}={patched_hash}")
        print(patched_adf)
    (OUT_DIR / "manifest.txt").write_text("\n".join(summary) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
