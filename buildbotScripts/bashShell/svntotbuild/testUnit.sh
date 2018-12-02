#!/usr/bin/env bash
set -e
source setEnv.sh

set -x
nice -n 10 ninja -C "$buildDir" check-llvm
