#!/usr/bin/env bash
set -e -x
config=(${1//,/ })

compiler=${config[1]}
arch=${config[2]}

function clean {
  svn status $lldbDir/test --no-ignore | grep '^[I?]' | cut -c 9- | while IFS= read -r f; do echo "$f"; rm -rf "$f"; done || true
  killall -9 lldb || true
  killall -9 a.out || true
}
trap clean EXIT

if [ $compiler == "totclang" ]
then
  compiler=$buildDir/bin/clang
fi

if [ "${compiler:0:1}" == "/" ]
then
  ccdir=$(dirname "${compiler}")/..
  export LD_LIBRARY_PATH=$ccdir/lib64:$ccdir/lib32:$ccdir/lib
fi
cc_log=${config[1]////-}

"$lldbDir/test/dotest.py" \
  --executable "$buildDir/bin/lldb" \
  -A "$arch" -C "$compiler" \
  -v -s "logs-$cc_log-$arch" \
  -u CXXFLAGS -u CFLAGS \
  --env ARCHIVER=ar --env OBJCOPY=objcopy \
  --channel "gdb-remote packets" \
  --channel "lldb all"
