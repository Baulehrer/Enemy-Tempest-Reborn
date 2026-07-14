# Enemy 1 Intro: 1.0 Acceptance Gate

Reborn ships the Enemy 1 intro as German and English videos captured under a
locally owned original Kickstart. The independent Enemy port remains a separate
project and is not replaced by these videos.

## Capture evidence

For both languages retain the source ADF and ROM hashes, FS-UAE version, full
configuration, raw capture hash, final video hash, capture time and exact trim
points. Original Kickstart ROM files stay outside the repository and packages.

## Video requirements

- The first frame is after the initial Kickstart/Workbench display.
- The final frame is immediately before Workbench returns.
- Every intro scene and the complete credits sequence is present.
- The stereo audio track is synchronized, audible and free of host sounds.
- The video preserves the original aspect ratio inside a black fullscreen
  presentation without desktop or window chrome.

## Launcher requirements

The selected language chooses the matching video. Playback must not start
FS-UAE, must fill the launcher surface with correct aspect ratio, close
automatically at end, and allow any key or mouse click to return to the menu.

## Pass condition

Both packaged videos pass the requirements above on clean Linux and Windows
packages. Their SHA-256 values appear in the release content manifest, and the
package contains no original Kickstart ROM.
