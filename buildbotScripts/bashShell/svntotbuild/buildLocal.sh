#!/usr/bin/env bash
set -e
source setEnv.sh
source cleanUp.sh

set -x
ninja -C "${buildDir}" \
	$(ninja -C "${buildDir}" -t targets all | cut -d: -f1 | grep '^[^-]*TableGen$')
ninja -C "${buildDir}" \
	$(ninja -C "${buildDir}" -t targets all | cut -d: -f1 | grep '\.a$')
ninja -j 4 -C "${buildDir}"
markBuildComplete
