# Graphics Baseline

Date: 2026-07-02

This baseline captures the current unmodified FS-UAE 3.2.35 output for the
Enemy 1 German intro path. It is intended as the reference set for later scale,
filter, CRT, shader, and FS-UAE fork work.

## Capture Setup

- Profile: `intro-de`
- Config: `configs/fs-uae/tempestreborn_intro_de_a1200.fs-uae`
- Emulator: FS-UAE 3.2.35
- Kickstart: bundled AROS ROM/ext ROM
- Display path: current default fullscreen profile
- Screenshot type: FS-UAE internal `crop` screenshots
- Crop size: 640 x 400

Command used:

```bash
INTRO_DURATION=76 INTRO_SHOTS="32 46 60 70" INTRO_INPUT_AT=999 \
  ./scripts/smoke_tempestreborn_profiles.sh intro-de
```

## Reference Frames

| Time | File | Purpose |
| --- | --- | --- |
| 32s | `evidence/screenshots/graphics-baseline-intro-de-32s-anachronia.png` | Logo, patterned background, text edges |
| 46s | `evidence/screenshots/graphics-baseline-intro-de-46s-starfield.png` | Dense single-pixel stars and dark gradients |
| 60s | `evidence/screenshots/graphics-baseline-intro-de-60s-ship-entry.png` | Sprite edges entering over starfield |
| 70s | `evidence/screenshots/graphics-baseline-intro-de-70s-fleet.png` | Multiple ship sprites, bright highlights, hard pixel edges |

## Notes

The earlier 18s frame from the first run was intentionally not kept because it
was a very dark transition frame. The 70s frame gives a more useful reference
for later graphics work.

These images are not a final quality target. They are the current baseline: any
future graphics change should be compared against them to prove whether it is
cleaner, blurrier, distorted, or cropped differently.
