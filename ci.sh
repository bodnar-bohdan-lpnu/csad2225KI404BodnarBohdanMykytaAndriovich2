#!/usr/bin/env bash

# Simple local CI script for configuring, building, and testing with CMake.
set -o pipefail

BUILD_DIR="build"

mkdir -p "$BUILD_DIR" || exit 1
cd "$BUILD_DIR" || exit 1

if cmake .. && cmake --build . && ctest; then
  echo "Build and tests succeeded."
  exit 0
else
  echo "Build failed."
  exit 1
fi
