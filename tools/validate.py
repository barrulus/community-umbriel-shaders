#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Barrulus
"""Validate every installation example without touching the user's configuration.

Requires Python 3.11+ and upstream Umbriel with the preset effects API.
This checks configuration and files, not GPU shader compilation.
"""

import argparse
import json
from pathlib import Path
import re
import subprocess
import tempfile
import tomllib


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--umbriel", default="umbriel", help="Umbriel executable")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    definitions = sorted(root.glob("*/*/effect.toml"))
    names = set()
    dependencies = set()

    def validate(config):
        result = subprocess.run(
            [args.umbriel, "validate", "-c", str(config)],
            capture_output=True, text=True, check=False,
        )
        output = result.stdout + result.stderr
        if result.returncode or "warning:" in output:
            raise RuntimeError(f"{config}:\n{output}")

    with tempfile.TemporaryDirectory(prefix="umbriel-community-check-") as temporary:
        staging = Path(temporary)
        (staging / "shaders").mkdir()
        (staging / "shaders/community").symlink_to(root, target_is_directory=True)
        for definition in definitions:
            directory = definition.parent
            data = tomllib.loads(definition.read_text())
            for path in data.get("include", {}).get("files", []):
                dependency = (directory / path).resolve()
                if not dependency.is_relative_to(root) or not dependency.is_file():
                    raise ValueError(f"Invalid dependency: {definition}: {path}")
                dependencies.add(dependency)
            for name, preset in data["effects"]["preset"].items():
                if name in names:
                    raise ValueError(f"Duplicate preset: {name}")
                names.add(name)
                kind = preset["kind"]
                if kind != directory.parent.name:
                    raise ValueError(f"Preset kind does not match directory: {definition}")
                shader = (directory / preset["shader"]).resolve()
                if not shader.is_relative_to(root) or not shader.is_file():
                    raise ValueError(f"Missing shader: {shader}")
                source = shader.read_text()
                if not 0 < shader.stat().st_size <= 256 * 1024:
                    raise ValueError(f"Invalid shader size: {shader}")
                if not re.search(r"\bvec4\s+" + kind + r"\s*\(\s*vec2\s+", source):
                    raise ValueError(f"Missing {kind} entry point: {shader}")
            for required in ("README.md", "config.toml", "preview.png"):
                if not (directory / required).is_file():
                    raise ValueError(f"Missing {directory / required}")
            config = staging / "config.toml"
            config.write_text((directory / "config.toml").read_text())
            validate(config)

        # Border presets already include their overlays. Avoid duplicate includes.
        config = staging / "all.toml"
        config.write_text("[include]\nfiles = " + json.dumps([
            str(path) for path in definitions if path.resolve() not in dependencies
        ]) + "\n")
        validate(config)
    print(f"Passed: {len(definitions)} installation examples and the combined library.")
    print("GPU compilation and visual testing must be performed separately.")


if __name__ == "__main__":
    main()
