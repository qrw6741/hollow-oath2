#!/usr/bin/env sh
# Runs the automated gameplay tests. Set GODOT to your Godot 4.3 binary.
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.." && "$GODOT" --headless --path . --fixed-fps 60 res://tests/run_tests.tscn
