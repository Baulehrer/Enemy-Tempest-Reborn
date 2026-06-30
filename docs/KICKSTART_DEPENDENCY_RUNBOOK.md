# Kickstart Dependency Runtime Runbook

This runbook captures the runtime evidence that the static/log analysis cannot
prove by itself.

## Goal

Determine whether Enemy uses Kickstart only to boot from disk, or whether the
loaded game/loader continues to call Kickstart ROM code after bootblock handoff.

## Baseline Command

Use the known-working A500/Kickstart 1.3 profile:

```bash
./scripts/run_enemy_aros.sh enemy1 a500 original
```

For a reproducible capture harness, use:

```bash
./scripts/capture_kickstart_runtime.sh enemy1 a500 original 20
```

This writes one capture directory under `work/kickstart-deps/runtime/` with the
FS-UAE stdout log, copied `debug.uae`, copied FS-UAE log, the exact config, and
a manifest. It also starts FS-UAE with console debugger output enabled and
sends the debugger hotkey via `ydotool`.

Current local method: FS-UAE must be started with `--console_debugger=1` and
`--stdout=1`; then `F12+D` enters the console debugger on Linux. The capture
wrapper sends this as evdev keycodes `88` (F12) and `32` (D). A successful
capture has `debugger_prompt_found=yes`, `debugger_register_dump_found=yes`,
and `debugger_prompt_char_found=yes` in `capture_summary.txt`.

Map the captured debugger PC back to the ROM file and offset with:

```bash
./scripts/map_debugger_pc.py work/kickstart-deps/runtime/<capture-dir>
```

This writes `pc_map_report.md` next to the capture. Current reference captures:

- Original Kickstart 1.3 A500:
  `work/kickstart-deps/runtime/enemy1_original_a500_20260628T101155+0200`
  maps `Next PC=0x00fc0f96` to the 256 KiB Kickstart ROM at offset `0x000f96`.
- AROS 2026 A500:
  `work/kickstart-deps/runtime/enemy1_aros_a500_20260628T101244+0200` maps
  `Next PC=0x00fe88c6` to `roms/aros/aros-rom.bin` at offset `0x0688c6`.

Source correlation and later AROS captures are documented in
`docs/AROS_SOURCE_CORRELATION.md`.

The comparison profiles are:

```bash
./scripts/run_enemy_aros.sh enemy1 a500 aros
./scripts/run_enemy_aros.sh enemy1 a500 arosnoext
./scripts/run_enemy_aros.sh enemy1 a500 aros2025
```

Equivalent capture commands:

```bash
./scripts/capture_kickstart_runtime.sh enemy1 a500 aros 20
./scripts/capture_kickstart_runtime.sh enemy1 a500 arosnoext 20
./scripts/capture_kickstart_runtime.sh enemy1 a500 aros2025 20
```

## Required Captures

Capture all registers and the current PC/SR at these points:

1. Immediately after cold reset.
2. At first bootblock execution.
3. At the first branch or return from bootblock into loaded code.
4. At any later PC in `$f80000-$ffffff`.

For each point, store:

- PC, SR, D0-D7, A0-A7.
- Longword at `$00000004` (`ExecBase` pointer).
- 1 KiB at the bootblock load address.
- 1 KiB around the current PC.
- FS-UAE log path and run id.

## Classification Rules

- `boot-only`: PC enters Kickstart before or during bootblock loading only.
- `game-calls-rom`: PC enters `$f80000-$ffffff` after bootblock handoff.
- `exec-vector`: loaded code calls through A6-relative library vectors.
- `hardware-direct`: loaded code accesses custom/CIA registers directly without
  a ROM call at that boundary.
- `unknown`: PC/handoff boundary is not proven.

## Acceptance

The dependency report is complete when it can answer:

- Does Enemy execute its bootblock under original Kickstart 1.3?
- Does any non-bootblock Enemy code call Kickstart ROM?
- If yes, which ROM/library vectors are required first?
- If no, what minimum boot services are needed for an Enemy-only boot ROM?
