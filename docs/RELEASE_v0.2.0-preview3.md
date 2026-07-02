# Enemy: Tempest Reborn v0.2.0-preview3

Date: 2026-07-01

This Linux preview supersedes `v0.2.0-preview2` and adds the first project-local
keyboard joystick profile.

## New Since preview2

- Cursor keys still control the Amiga joystick.
- WASD now also controls joystick directions.
- `Space` now acts as joystick fire.
- Right `Ctrl`, Right `Alt`, and Right `Shift` are fire alternatives.
- `H` maps to the Amiga `HELP` key.
- Original Enemy keys such as `P`, `R`, `Backspace`, `Delete`, and `Esc` remain
  available.

## Runtime Defaults

- fullscreen launch path
- `zoom = auto` for all Tempest Reborn FS-UAE profiles
- floppy drive speed at maximum
- floppy sounds disabled
- A1200 profile with 2 MB Chip RAM and 2 MB Fast RAM
- bundled FS-UAE 3.2.35 plus runtime data

`F12` opens the internal FS-UAE menu. `F11` cycles FS-UAE zoom modes.

## Keyboard Mapping Implementation

The package includes:

```text
configs/fs-uae-data/Devs/Keyboards/Keyboard.ini
```

All Tempest Reborn FS-UAE profiles set:

```text
data_dir = configs/fs-uae-data
```

The keyboard profile keeps the Amiga joystick mapping explicit:

```text
key_left = left
key_right = right
key_up = up
key_down = down
key_a = left
key_d = right
key_w = up
key_s = down
key_space = 1
key_rctrl = 1
key_ralt = 1
key_rshift = 1
```

## Verification

Short FS-UAE smoke against `enemy1-de` confirmed:

```text
- using "Data" directory "configs/fs-uae-data"
read config for Keyboard for amiga (from configs/fs-uae-data/Devs/Keyboards/Keyboard.ini)
key_space (32) => action "1"
key_w (119) => action "up"
```

`flutter analyze` also passed.

## Known Preview Limitations

- Linux x64 only.
- FS-UAE is bundled from the local system package for this preview.
- This is not yet the future patched FS-UAE fork; graphics/filter work still
  belongs to later v0.2.x milestones.
