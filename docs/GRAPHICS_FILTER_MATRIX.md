# Graphics Filter Matrix

Date: 2026-07-03

This document defines the reproducible graphics filter comparison used for
Enemy: Tempest Reborn.

## External Preview Sources

There is no single authoritative preview gallery for the exact FS-UAE shader
stack on Enemy. The closest reliable sources are:

- FS-UAE `shader` option documentation: lists bundled shader names such as
  `crt-guest`, `crt-hyllian`, `crt-lottes`, `crt`, `hq2x`, `scale2x`,
  `scale4xhq`, `scalefx`, `sharp-bilinear`, `super-xbr-3p`, `xbrz4x`, and
  `xbrz6x`: <https://fs-uae.net/docs/options/shader/>
- FS-UAE `effect` option documentation: lists the built-in effect choices
  `0`, `2x`, `hq2x`, `scale2x`, and `crt`:
  <https://fs-uae.net/docs/options/effect/>
- FS-UAE `texture_filter` documentation: confirms that FS-UAE defaults to
  linear OpenGL texture filtering and that `nearest` forces GL_NEAREST:
  <https://fs-uae.net/docs/options/texture-filter/>
- General pixel-art scaler comparisons are useful for understanding the
  visual trade-offs, but they are not a replacement for testing against Enemy:
  <https://en.wikipedia.org/wiki/Comparison_gallery_of_image_scaling_algorithms>

## Local Test

Run:

```bash
./scripts/capture_graphics_filter_matrix.sh
```

On GNOME/Wayland, host screenshots through `gnome-screenshot` are blocked for
non-interactive automation. For shader-visible host captures, run FS-UAE through
XWayland:

```bash
SDL_VIDEODRIVER=x11 ./scripts/capture_graphics_filter_matrix.sh sharp crt-shader crt-hyllian crt-lottes scanline-3x
```

Default source:

```text
configs/fs-uae/tempestreborn_intro_de_a1200.fs-uae
```

Default capture point:

```text
70 seconds into the German intro
```

Default variants:

```text
sharp
smooth
scanlines
crt-effect
crt-shader
crt-hyllian
crt-lottes
hq2x
scale2x
scale4xhq
xbrz4x
xbrz6x
super-xbr-3p
scalefx
scanline-3x
sharp-bilinear
```

Outputs:

```text
work/graphics-filter-matrix/<run-id>/
evidence/screenshots/graphics-filter-matrix/<run-id>/
```

The `work` directory keeps full temporary runtime state. The `evidence`
directory keeps the manifest, generated test configs, and screenshots intended
for review.

## Selection Criteria

Keep only options that pass these checks:

- FS-UAE accepts the option without silently falling back.
- The effect is visible in a host-side screenshot, not only present in config.
- Enemy text remains readable.
- Sprites and starfield details do not smear excessively.
- The result is useful as a player choice, not just a technical curiosity.

## Launcher Preset Mapping

```text
Original       -> texture_filter = nearest, smoothing = 0
Retro          -> shader = crt-hyllian
Retro Plus     -> shader = crt-lottes
Enhanced       -> shader = scalefx
Enhanced Plus  -> shader = xbrz6x
```

The launcher displays the preset names as the primary player-facing choice and
shows the underlying shader name as a small technical subtitle.

## Current Recommendation

Based on the 2026-07-03 runs:

```text
Keep:
  Original       baseline, deterministic, already default
  Retro          CRT Hyllian, visible CRT/scanline result, moderate strength
  Retro Plus     CRT Lottes, visible CRT/mask result, strong and darker
  Enhanced       ScaleFX, measurable internal image change, subtle but real
  Enhanced Plus  xBRZ 6x, measurable internal image change, subtle but real

Manual review candidates:
  CRT shader   visible host-side curvature/CRT effect, stronger style
  Scanline 3x  visible host-side scanline result, simpler than CRT Hyllian

Reject for now:
  effect = crt
  effect = hq2x
  effect = scale2x
  shader = xbrz4x
  shader = scale4xhq
  shader = sharp-bilinear
  shader = super-xbr-3p
```

Reason: FS-UAE internal screenshots capture the Amiga frame before final
OpenGL shader presentation. They are useful for scaler candidates such as
`scalefx` and `xbrz6x`, but they do not prove CRT/scanline host shaders.
The XWayland host-window capture in run `20260703T111408+0200` confirms that
`crt`, `crt-hyllian`, `crt-lottes`, and `scanline-3x` are visibly different.

## Run 20260703T085830+0200

First matrix run:

```text
evidence/screenshots/graphics-filter-matrix/20260703T085830+0200/
```

Variants:

```text
sharp smooth scanlines crt-effect hq2x scale2x xbrz4x scalefx
```

Result:

- All variants reached the capture point and were terminated by the expected
  timeout.
- Desktop screenshots were unavailable in this environment, so the evidence is
  based on FS-UAE's internal `crop`, `full`, and `real` screenshots plus stdout
  logs.
- `xbrz4x` and `scalefx` compiled as real FS-UAE shaders.
- `scalefx` changed the internal crop screenshot versus `sharp`.
- `smooth`, `scanlines`, `crt-effect`, `hq2x`, `scale2x`, and `xbrz4x` were
  byte-identical to `sharp` in the internal crop screenshot.

ImageMagick absolute-error comparison against `sharp` crop:

```text
smooth       0
scanlines    0
crt-effect   0
hq2x         0
scale2x      0
xbrz4x       0
scalefx      14888
```

## Run 20260703T103418+0200

Second matrix run:

```text
evidence/screenshots/graphics-filter-matrix/20260703T103418+0200/
```

Variants:

```text
crt-shader crt-hyllian crt-lottes scale4xhq xbrz6x super-xbr-3p scanline-3x sharp-bilinear
```

Result:

- All variants reached the capture point and were terminated by the expected
  timeout.
- `crt`, `crt-hyllian`, `crt-lottes`, `scale4xhq`, `xbrz6x`,
  `scanline-3x`, and `sharp-bilinear` compiled as real FS-UAE shaders.
- `super-xbr-3p` failed fragment shader compilation on this system and loaded
  no shader passes.
- `xbrz6x` changed the internal crop screenshot versus `sharp`.
- The CRT and scanline shader candidates were byte-identical to `sharp` in the
  internal crop screenshot, despite successful shader compilation.

ImageMagick absolute-error comparison against `sharp` crop:

```text
crt-shader      0
crt-hyllian     0
crt-lottes      0
scale4xhq       0
xbrz6x          13588
super-xbr-3p    0
scanline-3x     0
sharp-bilinear  0
```

## Run 20260703T111408+0200

Third matrix run with host-window capture through XWayland:

```bash
CAPTURE_AT=70 RUN_SECONDS=76 SDL_VIDEODRIVER=x11 ./scripts/capture_graphics_filter_matrix.sh sharp crt-shader crt-hyllian crt-lottes scanline-3x
```

Evidence:

```text
evidence/screenshots/graphics-filter-matrix/20260703T111408+0200/
```

Result:

- Host screenshots were captured as `desktop_70s.png`.
- All shader candidates compiled successfully.
- CRT/scanline candidates are visibly different from `sharp` in the host
  capture.
- This corrects the earlier internal-screenshot-only interpretation.

ImageMagick absolute-error comparison against `sharp` host screenshot:

```text
crt-shader   575686
crt-hyllian  572678
crt-lottes   574753
scanline-3x  574722
```

Visual notes:

```text
crt-shader   Curved CRT look, strong black border and curvature.
crt-hyllian  Clean scanlines with moderate CRT feel; best first CRT candidate.
crt-lottes   Strong mask/CRT look, darker and more stylized.
scanline-3x  Simple scanlines, less character than CRT Hyllian.
```
