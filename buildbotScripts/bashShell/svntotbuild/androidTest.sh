#!/usr/bin/env bash
set -e
config=(${1//,/ })
export deviceId=${config[0]}
export compiler=${config[1]}
export arch=${config[2]}
export socket=${config[3]}
function clean {
  svn status $lldbDir/test --no-ignore | grep '^[I?]' | cut -c 9- | while IFS= read -r f; do echo "$f"; rm -rf "$f"; done || true
  adb -s $deviceId shell ps | grep lldb-server | awk '{print $2}' | xargs adb -s $deviceId shell kill || true
  adb -s $deviceId shell rm -r $remoteDir || true
}
trap clean EXIT

set -x
adb -s $deviceId shell getprop ro.build.fingerprint
adb -s $deviceId shell ps | grep lldb-server | awk '{print $2}' | xargs adb -s $deviceId shell kill || true
adb -s $deviceId shell rm -r $remoteDir || true
adb -s $deviceId shell mkdir $remoteDir
adb -s $deviceId push $buildDir/android-$arch/bin/lldb-server $remoteDir/
adb forward --remove-all

if [ "$socket" == "abstract" ]
then
  socket_name=lldb-platform.sock
  listen_url=unix-abstract://$remoteDir/$socket_name
  connect_url=unix-abstract-connect://$deviceId$remoteDir/$socket_name
else
  listen_url=127.0.0.1:$port
  connect_url=connect://$deviceId:$port
fi
adb -s "$deviceId" shell <<-EOF &>/dev/null &
    export TMPDIR="$remoteDir/tmp"
    export LLDB_DEBUGSERVER_LOG_FILE=server.log
    export LLDB_SERVER_LOG_CHANNELS="gdb-remote packets:lldb all"
    exec "$remoteDir/lldb-server" platform --listen $listen_url --server
EOF

export LLDB_TEST_THREADS=8

if [[ "$compiler" == *-clang ]]; then
  toolchain=llvm
  compiler=clang
else
  if [[ "$compiler" == i686-* ]]; then
    toolchain=x86-4.9
  elif [[ "$compiler" == x86_64-* ]]; then
    toolchain=x86_64-4.9
  else
    toolchain=${compiler//-gcc}-4.9
  fi
fi

host=$(uname -s | tr '[:upper:]' '[:lower:]')

"$lldbDir/test/dotest.py" \
  --executable "$buildDir/bin/lldb" \
  -A "$arch" -C "$ANDROID_NDK_HOME/toolchains/$toolchain/prebuilt/$host-x86_64/bin/$compiler" \
  -v -s "logs-$compiler-$arch-$deviceId" -u CXXFLAGS -u CFLAGS \
  --channel "gdb-remote packets" --channel "lldb all" \
  --platform-name remote-android \
  --platform-url "$connect_url" \
  --platform-working-dir "$remoteDir" \
  --env OS=Android \
  --skip-category lldb-mi
