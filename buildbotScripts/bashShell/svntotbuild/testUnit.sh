#!/usr/bin/env bash
set -e
source setEnv.sh

set -x
nice -n 10 ninja -k 9999 -C "$buildDir" check-lld
