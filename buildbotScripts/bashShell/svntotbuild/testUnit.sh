#!/usr/bin/env bash
set -e
source setEnv.sh

set -x
nice -n 10 ninja -C "$buildDir" check-lit check-llvm check-clang check-clang-tools check-lld
