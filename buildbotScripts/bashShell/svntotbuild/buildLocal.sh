#!/usr/bin/env bash
set -e
source setEnv.sh
source cleanUp.sh

# add periodical status 'pings'
run_status_pings() {
	while :; do
		sleep 300
		date '+[%F %T]'
	done
}
run_status_pings &
st_ping_pid=$!
trap 'kill "${st_ping_pid}"' EXIT

set -x
ninja -C "${buildDir}" \
	$(ninja -C "${buildDir}" -t targets all | cut -d: -f1 | grep '^[^-]*TableGen$')
ninja -C "${buildDir}" \
	$(ninja -C "${buildDir}" -t targets all | cut -d: -f1 | grep '\.a$' | grep -v libcxx)
ninja -j 4 -C "${buildDir}" clang
ninja -j 4 -C "${buildDir}"
markBuildComplete
