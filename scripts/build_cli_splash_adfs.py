#!/usr/bin/env python3
"""Build ADF variants with a simple AmigaDOS CLI title screen.

The original Enemy ADFs have a bitmap mismatch that makes in-place filesystem
edits unreliable with xdftool. This script extracts the already patched ADFs
with unadf, replaces only s/startup-sequence, and writes clean bootable ADFs.
No extra viewer, image, or library is added.
"""

from __future__ import annotations

import hashlib
import os
import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "work/kickstart-deps/patches/cli-splash"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


@dataclass(frozen=True)
class Target:
    name: str
    source: Path
    expected_sha256: str
    startup: str


FRAME_WIDTH = 60


def frame(text: str = "") -> str:
    if len(text) > FRAME_WIDTH:
        raise SystemExit(f"CLI splash line too long: {text!r}")
    return "   ##" + text.center(FRAME_WIDTH) + "##"


def rule() -> str:
    return "   " + "#" * (FRAME_WIDTH + 4)


def title_lines() -> list[str]:
    return [
        "",
        rule(),
        frame(),
        frame("######  ##   ##  ######  ##   ##  ##   ##"),
        frame("##      ###  ##  ##      ### ###   ## ## "),
        frame("#####   #### ##  #####   #######    ###  "),
        frame("##      ## ####  ##      ## # ##     ##  "),
        frame("######  ##   ##  ######  ##   ##     ##  "),
        frame(),
        frame("E N E M Y   -   T E M P E S T   R E B O R N"),
        frame(),
        rule(),
        frame(),
        frame("A N A C H R O N I A   x   A R O S   U A E"),
        frame(),
        rule(),
        "",
        "        PROJECT  : Stephan Kaufmann",
        "        ORIGINAL : Andre Wuethrich / Anachronia",
        "        SYSTEM   : AROS Kickstart + FS-UAE",
        "",
        "        Loading Enemy...",
        "",
    ]


def cli_title() -> str:
    style_on = 'Echo "*E[0m*E[32m*E[41m"\n'
    clear_screen = 'Echo "*E[0;0H*E[J"\n'
    style_off = 'Echo "*E[0m"\n'
    output = style_on + clear_screen
    output += "".join(f'Echo "{line}"\n' for line in title_lines())
    return output + style_off


def game_startup(executable: str) -> str:
    return (
        cli_title()
        + "ENEMY_A:c/closewb\n"
        + f"ENEMY_A:{executable} >nil:\n"
    )


def intro_startup(executable: str) -> str:
    return cli_title() + f"ENEMY_A:{executable}\nendcli\n"


TARGETS = [
    Target(
        name="enemy1_de",
        source=ROOT
        / "work/kickstart-deps/patches/level-unlock/ENEMY1_V2_DE_A.game-nointro.level-unlock.adf",
        expected_sha256="00bd8ef151247db37ff7316ff465c3626673bbeacee25827d3aaadbce9388760",
        startup=game_startup("ef/enemy"),
    ),
    Target(
        name="enemy1_en",
        source=ROOT
        / "work/kickstart-deps/patches/level-unlock/ENEMY1_V2_EN_A.game-nointro.level-unlock.adf",
        expected_sha256="6d12932e445b827ce9275a6ede903d833dd84b6e82609f88104687d113999a2b",
        startup=game_startup("ef/enemy"),
    ),
    Target(
        name="enemy2_de",
        source=ROOT
        / "work/kickstart-deps/patches/level-unlock/ENEMY2_V2_DE_A.closewb-nop.level-unlock.adf",
        expected_sha256="c47c81cb69fb55dc680bcb5ccaa4793412d92429c0a96f16f626e98026e2e925",
        startup=game_startup("ef/enemy2"),
    ),
    Target(
        name="enemy2_en",
        source=ROOT
        / "work/kickstart-deps/patches/level-unlock/ENEMY2_V2_EN_A.closewb-nop.level-unlock.adf",
        expected_sha256="5a9db109a2bf96c6abbda46e3a8bd9046f3354ed4e0f841be20d1b084f35626b",
        startup=game_startup("ef/enemy2"),
    ),
    Target(
        name="intro_de",
        source=ROOT / "work/kickstart-deps/patches/enemy1-boot-split/ENEMY1_V2_DE_A.intro-only.adf",
        expected_sha256="036864cfc7eb690a0ffb2344281dd03f4c0f5401a12ff1bde6b6c7298c4a35a2",
        startup=intro_startup("enif/enintro"),
    ),
    Target(
        name="intro_en",
        source=ROOT / "work/kickstart-deps/patches/enemy1-boot-split/ENEMY1_V2_EN_A.intro-only.adf",
        expected_sha256="09f276caba0a5c7491cf3bee2c857467f2d2481085790dcf50a334dd606b2206",
        startup=intro_startup("enif/enintro"),
    ),
]


def run(args: list[str], *, cwd: Path | None = None, stdout=None) -> None:
    subprocess.run(args, cwd=cwd, stdout=stdout, check=True)


def extracted_root(extract_dir: Path) -> Path:
    if (extract_dir / "s").is_dir():
        return extract_dir
    dirs = [path for path in extract_dir.iterdir() if path.is_dir()]
    if len(dirs) == 1:
        return dirs[0]
    raise SystemExit(f"Could not find extracted ADF root in {extract_dir}")


def write_clean_adf(source_root: Path, target_adf: Path) -> None:
    if target_adf.exists():
        target_adf.unlink()

    run(["xdftool", str(target_adf), "create"])
    run(["xdftool", str(target_adf), "format", "ENEMY_A"])

    dirs = sorted(
        [path for path in source_root.rglob("*") if path.is_dir()],
        key=lambda path: (len(path.relative_to(source_root).parts), str(path)),
    )
    for path in dirs:
        rel = str(path.relative_to(source_root)).replace(os.sep, "/")
        if rel != ".":
            run(["xdftool", str(target_adf), "makedir", rel])

    files = sorted(path for path in source_root.rglob("*") if path.is_file())
    for path in files:
        rel = str(path.relative_to(source_root)).replace(os.sep, "/")
        run(["xdftool", str(target_adf), "write", str(path), rel])

    run(["xdftool", str(target_adf), "boot", "install"])


def build_target(target: Target) -> tuple[Path, str]:
    if not target.source.exists():
        raise SystemExit(f"Missing source ADF: {target.source}")

    source_hash = sha256(target.source)
    if source_hash != target.expected_sha256:
        raise SystemExit(
            f"Unexpected source hash for {target.source}: "
            f"{source_hash}, expected {target.expected_sha256}"
        )

    with tempfile.TemporaryDirectory(prefix=f"{target.name}-cli-splash-") as tmp:
        extract_dir = Path(tmp) / "extract"
        extract_dir.mkdir()
        run(["unadf", str(target.source.resolve())], cwd=extract_dir, stdout=subprocess.DEVNULL)
        root = extracted_root(extract_dir)

        startup = root / "s" / "startup-sequence"
        startup.parent.mkdir(exist_ok=True)
        startup.write_text(target.startup, encoding="latin-1")

        output_name = target.source.name.replace(".adf", ".cli-splash.adf")
        output = OUT_DIR / output_name
        write_clean_adf(root, output)

    output_hash = sha256(output)
    manifest = output.with_suffix(".manifest.txt")
    manifest.write_text(
        "\n".join(
            [
                "patch=cli-splash-startup",
                f"name={target.name}",
                f"source_adf={target.source}",
                f"source_sha256={source_hash}",
                f"patched_adf={output}",
                f"patched_sha256={output_hash}",
                "startup_sequence:",
                target.startup.rstrip(),
                "",
            ]
        ),
        encoding="utf-8",
    )
    return output, output_hash


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    summary = ["patch_set=cli-splash-startup"]
    for target in TARGETS:
        output, output_hash = build_target(target)
        summary.append(f"{output.name}={output_hash}")
        print(output)

    (OUT_DIR / "manifest.txt").write_text("\n".join(summary) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
