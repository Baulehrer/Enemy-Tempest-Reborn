# Release Checklist

## Source and version

- [ ] Worktree is clean and the release commit is reviewed.
- [ ] Tag, launcher version, Flutter version and package version agree.
- [ ] Flutter analyze, tests and repository validation pass.
- [ ] Patched ADFs reproduce from the documented source hashes.

## Runtime acceptance

- [ ] Enemy 1 DE and EN reach the menu and start a level.
- [ ] Enemy 2 DE and EN reach the menu and start a level.
- [ ] Intro DE and EN show the complete reference scene sequence and exit.
- [ ] Keyboard, gamepad and joystick profiles are checked.
- [ ] Every graphics preset is checked on Linux and Windows.
- [ ] Fullscreen, window, 4:3, pixel-perfect and stretch are checked.

## Packages

- [ ] Linux tarball and AppImage run on a clean supported system.
- [ ] Windows ZIP and installer run without a separate FS-UAE install.
- [ ] Install, upgrade and uninstall preserve user data correctly.
- [ ] macOS output is labelled Preview unless native runtime gates pass.
- [ ] Package manifests and SHA-256 files verify after download.

## Legal and publication

- [ ] Enemy media and artwork distribution permission is archived.
- [ ] AROS, FS-UAE, shader and third-party notices match shipped files.
- [ ] Corresponding FS-UAE source/patch information is available.
- [ ] README DE/EN, changelog and release notes match the artifacts.
- [ ] A second person has completed the final clean-system check.
