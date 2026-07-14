# Enemy: Tempest Reborn

Version 0.9.5

Enemy: Tempest Reborn is a simple launcher package for playing Enemy 1 and
Enemy 2 through FS-UAE. The goal is to make the games easy to start, with a
clean menu, prepared settings, and a few graphics presets.

![Enemy: Tempest Reborn launcher](docs/images/tempest-reborn-launcher.png)

![Enemy: Tempest Reborn launch splash](docs/images/tempest-reborn-splash.png)

## Features

- Enemy 1: Tempest of Violence
- Enemy 2: Missing in Action
- German and English game versions
- Complete German and English Enemy 1 intro videos captured under original
  Kickstart
- Fullscreen-first setup
- Prepared graphics presets:
  - Original
  - Retro
  - Retro Plus
  - Enhanced
  - Enhanced Plus
- Keyboard, joystick, and gamepad profiles
- Level selection prepared for normal play
- Short host launch splash while FS-UAE starts
- Clean Amiga-side CLI splash instead of raw AROS boot text
- Windows installer
- Linux AppImage
- Portable Linux and Windows packages
- macOS preview package

## The Menu

The menu lets you choose the game, language, graphics preset, screen mode, and
control style before starting FS-UAE.

Enemy 1 starts directly at the game menu. The intro is available as its own
menu entry and plays the bundled original-Kickstart capture without starting
FS-UAE. Any key or mouse click returns to the launcher.

The graphics presets are meant as simple choices:

- Original keeps the sharp classic look.
- Retro adds a CRT-style presentation.
- Enhanced smooths the pixel art more strongly.

## Controls

Keyboard, joystick, and gamepad can be selected in the menu. The keyboard setup
supports cursor keys and WASD for movement. Gamepad and joystick are intended
for a more original Amiga-like feel.

## Known Notes

The games are packaged around the tested AROS/FS-UAE profiles and prepared ADF
patches. The bundled intro videos are derived captures; no Commodore Kickstart
ROM is included.

## Release Pipeline

The project uses GitHub Actions to build release packages. A release tag starts
the package builds for Linux, Windows, and macOS. The pipeline creates the
portable archives, the Linux AppImage, and the Windows installer, then uploads
them to the GitHub release.

## Thanks

Thanks to the AROS project for the free Amiga-compatible system work that makes
this package possible.

Thanks to FS-UAE for the emulator base used by the release packages.

Special thanks to André Wüthrich <anachronia@gmail.com> for Enemy and
Anachronia.

## License

See `LICENSES.md` for the included licenses and third-party notices.
