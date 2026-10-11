#!/bin/sh
# Subsets the bundled fonts to the characters the game can display (keeps the download small).
# Originals live in tools/fonts_src/. Re-run after adding characters outside the ranges below.
set -e
U="U+0020-007E,U+00A0-017F,U+2010-2027,U+2030-203A,U+2190-2193,U+2212,U+2261,U+00B7"
F="kern,liga,calt,locl,mark,mkmk,lnum,onum,pnum,tnum"
cd "$(dirname "$0")/.."
pyftsubset tools/fonts_src/Lora-Variable.ttf --unicodes="$U" --layout-features="$F" --output-file=assets/fonts/Lora-Variable.ttf --no-hinting --desubroutinize
pyftsubset tools/fonts_src/GFSBaskerville.otf --unicodes="$U" --layout-features="$F" --output-file=assets/fonts/GFSBaskerville.otf --no-hinting --desubroutinize
ls -l assets/fonts
