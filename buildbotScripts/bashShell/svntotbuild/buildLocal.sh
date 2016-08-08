#!/usr/bin/env bash
set -e
source setEnv.sh
source cleanUp.sh

set -x
nice -n 10 ninja -C "$buildDir"
markBuildComplete
