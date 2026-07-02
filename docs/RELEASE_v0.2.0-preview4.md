# Enemy: Tempest Reborn v0.2.0-preview4

Date: 2026-07-02

This Linux preview supersedes `v0.2.0-preview3` and fixes the keyboard control
profile after manual gameplay testing.

## New Since preview3

- Arrow keys are now explicitly mapped in the project keyboard profile.
- Right `Ctrl`, Right `Alt`, and Right `Shift` are explicitly mapped as fire.
- The Amiga gameplay section no longer depends on hidden FS-UAE default joystick
  mappings for cursor/fire behavior.
- Manual test confirmed that the previous arrow-key hold/freeze behavior is
  gone.

## Keyboard Controls

| Action | Keyboard |
| --- | --- |
| Left | Arrow Left or `A` |
| Right | Arrow Right or `D` |
| Up / aim up / use / climb | Arrow Up or `W` |
| Down / aim down / pick up / crouch | Arrow Down or `S` |
| Fire / action / menu confirm | `Space` |
| Fire alternatives | Right `Ctrl`, Right `Alt`, Right `Shift` |

Original Enemy keys such as `P`, `R`, `Backspace`, `Delete`, and `Esc` remain
available.

## Verification

Short FS-UAE smoke against `enemy1-de` confirmed:

```text
read config for Keyboard for amiga (from configs/fs-uae-data/Devs/Keyboards/Keyboard.ini)
key_space  => action "1"
key_rshift => action "1"
key_down   => action "down"
key_up     => action "up"
key_ralt   => action "1"
key_left   => action "left"
key_rctrl  => action "1"
key_right  => action "right"
```

Manual test result:

```text
WASD, Space and the explicit arrow/fire mappings work.
Holding arrow keys no longer freezes gameplay.
```

## Runtime Defaults

- fullscreen launch path
- `zoom = auto` for all Tempest Reborn FS-UAE profiles
- floppy drive speed at maximum
- floppy sounds disabled
- A1200 profile with 2 MB Chip RAM and 2 MB Fast RAM
- bundled FS-UAE 3.2.35 plus runtime data

`F12` opens the internal FS-UAE menu. `F11` cycles FS-UAE zoom modes.
