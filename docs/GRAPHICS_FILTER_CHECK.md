# Graphics Filter Check

Date: 2026-07-02

This check verifies whether the current launcher `Pixels` options already
produce visible FS-UAE filtering.

## Result

No visible filtering difference was proven with the current options.

The launcher currently writes:

```text
Sharp  -> texture_filter = nearest, smoothing = 0
Smooth -> texture_filter = linear,  smoothing = 1
CRT    -> texture_filter = nearest, smoothing = 0, scanlines = 1
```

All six Tempest Reborn base profiles now also force the Sharp baseline:

```text
texture_filter = nearest
smoothing = 0
```

This makes the packaged profiles deterministic even when they are launched
outside the Flutter launcher.

FS-UAE accepted these keys in the temporary configs, but internal FS-UAE
screenshots for the same intro frame were byte-identical across all three
variants.

## Evidence

Temporary variants were run from the German intro profile:

```text
/tmp/enemy-graphics-filter-check/sharp.fs-uae
/tmp/enemy-graphics-filter-check/smooth.fs-uae
/tmp/enemy-graphics-filter-check/crt.fs-uae
```

All variants used:

```text
fullscreen = 0
window_width = 960
window_height = 720
zoom = auto
```

The logs showed the options were read:

```text
texture_filter = nearest
texture_filter = linear
scanlines = 1
setting (windowed) video mode 960 720
```

The generated `crop` and `full` screenshots were identical:

```text
sharp_crop  vs smooth_crop: changed_pixels=0
sharp_crop  vs crt_crop:    changed_pixels=0
sharp_full  vs smooth_full: changed_pixels=0
sharp_full  vs crt_full:    changed_pixels=0
```

The `real` screenshots in this environment were not useful for visual filter
comparison because they captured a blank/black output image.

## Interpretation

The saved FS-UAE screenshots capture the Amiga output before final host display
scaling/filtering. Therefore they are good for raw baseline comparison, but not
sufficient to prove host-side OpenGL filtering.

Still, the current evidence suggests the launcher `Smooth` and `CRT` modes are
not yet reliable user-visible graphics modes. The perceived softness is more
likely caused by fullscreen/window scaling with `zoom = auto` on a non-integer
host resolution than by a deliberate smoothing filter.

## Next Step

Test FS-UAE's native WinUAE-style filter options instead of the current
placeholder-style launcher values:

```text
gfx_filter_bilinear
gfx_filter_scanlines
gfx_filter_scanlinelevel
gfx_filter_horiz_zoom
gfx_filter_vert_zoom
gfx_filter_keep_aspect
```

If those options do not produce controllable, high-quality output, the graphics
enhancement work should move into the planned FS-UAE fork/render-path changes.
