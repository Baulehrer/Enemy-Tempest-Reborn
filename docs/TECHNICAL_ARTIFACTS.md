# Technical Artifacts

## Original Enemy ADF SHA-256

```text
f8a970e7225541c34d2322875df8294a73604afbab679d0ecb002a5ac01cc28e  ENEMY1_V2_DE_A.adf
b9a1d73977ad7fc21f0d4e44895dcf6096c6e67cc67e4ca0b8673d192c321e44  ENEMY1_V2_DE_B.adf
7639e8100cc7525d6f38c9343955b74f23e6666ca1de76c61803fb06cf767724  ENEMY2_V2_DE_A.adf
974d0b132ac238a49a022e5f9162302aaa2ebe7d446280176835ab161f6368d2  ENEMY2_V2_DE_B.adf
```

## AROS ROM SHA-256

```text
e91b7b780cc48e7e77a4d7681bc9629e8bd8656eaa8f379d79618df33a1be4c0  aros-ext.bin
d583b54aabf2294c082591eb5228af52a207a46f19b7586677233964f2e24b86  aros-rom.bin
d583ff8f40c73b1584a1395bb0869a909a96d2366a4ae9f4c15ab6a3d868ea62  aros-rom.20250816.bin
```

## Main Patch

Patch manifest from the workspace:

```text
patch=enemy1-closewb-nop
source_sha256=f8a970e7225541c34d2322875df8294a73604afbab679d0ecb002a5ac01cc28e
patched_sha256=a685d1c2d3f24ba70a96ed02f7e6385e463e3acf9d285de3e39d68f24597ea75
signature_offset=0x053042
checksum_block_offset=0x053000
old_checksum=0x3756ae9a
new_checksum=0x379f6741
patch_offset=0x053068
original_bytes=4eba0718
patched_bytes=4e714e71
runtime_effect=0006C440 JSR CloseWindow -> NOP; NOP
```

`4eba0718` is a 68k `JSR` to the local `CloseWindow` wrapper/call sequence in
the small `c/closewb` executable on the ADF. It is replaced by two NOPs:
`4e71 4e71`.

## Diagnostic Patch

The diagnostic ADF keeps the `closewb` NOP and modifies `s/startup-sequence` so
that shell output is visible instead of redirected to `nil:`.

```text
patch=enemy1-closewb-nop-diag
source_sha256=a685d1c2d3f24ba70a96ed02f7e6385e463e3acf9d285de3e39d68f24597ea75
patched_sha256=91f052a2105d962dcb62e8931792b85755f644782b3514dc6485c771e5b3de3f
startup_offset=0x06e618
checksum_block_offset=0x06e600
old_checksum=0x5ae9f86f
new_checksum=0x7051127e
```

## Hunk Summary

`ef/enemy` is a valid AmigaOS LoadSeg-style Hunk executable according to the
local parser and `file(1)`.

```text
enintro:
  bytes=34424 table_size=3 first=0 last=2
  blocks=HUNK_CODE:2, HUNK_BSS:1, HUNK_RELOC32:2, HUNK_END:3
  seg#0 CODE alloc=27292 relocs=491
  seg#1 CODE alloc=6116 payload=4836 relocs=54
  seg#2 BSS alloc=4

ef/enemy:
  bytes=311292 table_size=3 first=0 last=2
  blocks=HUNK_CODE:2, HUNK_BSS:1, HUNK_RELOC32:2, HUNK_END:3
  seg#0 CODE alloc=252316 relocs=10319
  seg#1 CODE alloc=51248 payload=15912 relocs=418
  seg#2 BSS alloc=4
```

This matters because AROS A500 reported `ef/enemy: file is not executable`, but
the file structure itself is not exotic: two CODE hunks, one BSS hunk, standard
RELOC32 blocks.

## Key Evidence Screenshots

- `evidence/screenshots/aros-a1200-closewb-nop-main-menu.png`
- `evidence/screenshots/aros-a1200-closewb-nop-shell-after-intro.png`

The main-menu screenshot proves that the NOP-patched run can leave the intro
and render the Enemy V2 main menu under AROS A1200/2 MB.

