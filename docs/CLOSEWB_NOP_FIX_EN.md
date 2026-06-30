# CloseWB NOP Fix - English Technical Notes

## Problem

Enemy V2 boots through AROS, but the original startup path behaved differently
depending on the emulated Amiga model and memory configuration.

The original startup sequence on disk A is:

```text
ENEMY_A:enif/enintro  >nil:
ENEMY_A:c/closewb
ENEMY_A:ef/enemy >nil:
```

On AROS A500-style configurations the run originally crashed or failed before a
clean main-game start. After the `CloseWindow()` call was bypassed, the A500
path reached the later `ef/enemy` LoadSeg attempt, where AROS reported:

```text
ENEMY_A:ef/enemy: file is not executable
```

Static Hunk analysis then showed that `ef/enemy` is still a normal LoadSeg file,
so that message was treated as an AROS/environment/resource symptom rather than
proof of a malformed executable.

## How the Patch Was Found

Runtime tracing focused on the small `c/closewb` helper. The relevant sequence
loads Intuition's `ActiveWindow`, pushes it, calls the local/linked
`CloseWindow()` call sequence, then performs normal stack cleanup.

The important runtime addresses in the AROS A500 capture were:

```text
callsite area: 0x0006c428 .. 0x0006c444
ActiveWindow argument observed around: 0x000625b8
return after call/cleanup: 0x0006c444
```

Further tracing showed that closing that window on AROS could lead into later
graphics/Exec memory corruption paths. The narrowest patch therefore did not
skip the entire helper. It only neutralized the single `CloseWindow()` call.

## Exact Binary Patch

Source:

```text
media/enemy-adfs/original/ENEMY1_V2_DE_A.adf
sha256=f8a970e7225541c34d2322875df8294a73604afbab679d0ecb002a5ac01cc28e
```

Patch:

```text
file offset in ADF: 0x053068
original bytes:     4eba0718
patched bytes:      4e714e71
effect:             JSR CloseWindow -> NOP; NOP
checksum block:     0x053000
old checksum:       0x3756ae9a
new checksum:       0x379f6741
```

Patched ADF:

```text
media/enemy-adfs/patched/ENEMY1_V2_DE_A.closewb-nop.adf
sha256=a685d1c2d3f24ba70a96ed02f7e6385e463e3acf9d285de3e39d68f24597ea75
```

The patch script is:

```text
scripts/build_closewb_nop_adf.py
```

It verifies the source ADF SHA-256, verifies a unique signature at the expected
offset, applies the two-NOP replacement, and recomputes the AmigaDOS block
checksum.

## What Was Tested

Successful path:

```text
AROS ROM: built 2026-06-21, Git f8e1bic2e
Machine:  A1200
Memory:   2 MB Chip RAM
ADF A:    ENEMY1_V2_DE_A.closewb-nop-diag.adf
ADF B:    ENEMY1_V2_DE_B.adf
Result:   intro runs, mouse/fire skips intro, main menu renders correctly
```

Control observation:

```text
Same AROS A1200/2 MB setup, original ADF without closewb NOP:
the game reaches Enemy video modes, but manual testing showed missing graphics.
```

A500 observation:

```text
AROS A500-style setup can report `ef/enemy: file is not executable`.
Hunk analysis does not support a malformed-Hunk explanation.
```

## Why This Is Useful For AROS Developers

This is a narrow compatibility reproducer:

- It isolates a single Intuition-facing call in a small helper executable.
- The binary patch is only four bytes and leaves the surrounding startup logic
  intact.
- The same `ef/enemy` Hunk executable is accepted and runs under AROS A1200/2 MB
  when this call is avoided.
- Without the patch, AROS can still run far enough to enter game video modes,
  but the resulting graphics state was not correct in manual testing.

The likely AROS-side investigation targets are:

- `CloseWindow()` behavior when called by this old AmigaDOS startup helper.
- Whether closing the active Shell/Workbench window leaves Intuition/Gfx state
  or memory lists in a state that affects later game rendering.
- Why AROS A500-style environments report `file is not executable` for a valid
  LoadSeg file, possibly due to memory/resource failure being surfaced as a
  misleading DOS error.

