#!/bin/zsh

set -euo pipefail

ORCA_DIR=$(orca sdk-path)

python3 ../../scripts/embed_text_files.py --prefix=glsl_ --output src/glsl_shaders.h src/shaders/*.glsl

# common flags to build wasm modules
wasmFlags=(--target=wasm32 \
  -mbulk-memory \
  -g -O2 \
  -Wl,--no-entry \
  -Wl,--export-dynamic \
  --sysroot "$ORCA_DIR"/orca-libc \
  -I "$ORCA_DIR"/src \
  -I "$ORCA_DIR"/src/ext)

# build sample as wasm module and link it with the orca module
clang "${wasmFlags[@]}" -L "$ORCA_DIR"/bin -lorca_wasm -o module.wasm src/main.c

# create app directory and copy files into it
orca bundle --name Fluid --icon icon.png module.wasm
