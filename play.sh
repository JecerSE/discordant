#!/usr/bin/env bash
# play.sh [godot args] - launch the game after refreshing Godot's script class cache.
# A plain `godot --path .` resolves class_name types only from .godot/, which only the editor
# or --import rebuilds. After a fresh clone, a branch switch or a pull that adds a class, a
# plain launch fails to compile main.gd and shows a blank page. The import is incremental:
# a few seconds when nothing changed.
set -euo pipefail
cd "$(dirname "$0")"
godot --headless --path . --import > /dev/null 2>&1 || true
exec godot --path . "$@"
