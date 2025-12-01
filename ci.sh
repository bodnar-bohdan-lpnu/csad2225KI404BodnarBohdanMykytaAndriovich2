#!/usr/bin/env bash

# Simple local CI script for configuring, building, and testing with CMake.
set -o pipefail

BUILD_DIR="build"
CONFIG="${CONFIG:-Debug}"

mkdir -p "$BUILD_DIR" || exit 1
cd "$BUILD_DIR" || exit 1

if cmake -DCMAKE_BUILD_TYPE="$CONFIG" .. \
  && cmake --build . --config "$CONFIG" \
  && ctest -C "$CONFIG" --output-on-failure; then
  echo "Build and tests succeeded."
  exit 0
else
  echo "Build failed."
  exit 1
fi
