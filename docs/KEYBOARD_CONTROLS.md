# Keyboard Controls

Date: 2026-07-01

Enemy remains controlled like the original Amiga game: joystick directions plus
one fire button. The host keyboard only emulates that joystick more comfortably.

## Main Controls

| Action | Keyboard |
| --- | --- |
| Left | Arrow Left or `A` |
| Right | Arrow Right or `D` |
| Up / aim up / use / climb | Arrow Up or `W` |
| Down / aim down / pick up / crouch | Arrow Down or `S` |
| Fire / action / menu confirm | `Space` |
| Fire alternative | Right `Ctrl`, Right `Alt`, or Right `Shift` |

## Original Enemy Keys

| Action | Keyboard |
| --- | --- |
| Pause | `P` |
| Replay | `R` |
| Jump back | `Backspace` |
| Show open missions | `Delete` |
| Help | `H` maps to Amiga `HELP` |
| Return to title screen | `Esc` |

## Implementation

The package includes a custom FS-UAE keyboard joystick profile:

```text
configs/fs-uae-data/Devs/Keyboards/Keyboard.ini
```

All Tempest Reborn FS-UAE profiles set:

```text
data_dir = configs/fs-uae-data
```

This keeps the keyboard mapping inside the project/package and avoids writing
controller profiles into the user's global `Documents/FS-UAE` directory.

The profile keeps the Amiga joystick mapping explicit:

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

The `[default]` section still includes FS-UAE's `default_keyboard` for non-Amiga
contexts such as menus, but the `[amiga]` section does not rely on hidden
defaults for gameplay.
