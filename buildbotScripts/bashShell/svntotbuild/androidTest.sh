#!/usr/bin/env bash
set -e
config=(${1//,/ })
deviceId=${config[0]}
compiler=${config[1]}
arch=${config[2]}
socket=${config[3]}
categories=(${config[4]//:/ })

function clean {
  svn status $lldbDir/test --no-ignore | grep '^[I?]' | cut -c 9- | while IFS= read -r f; do echo "$f"; rm -rf "$f"; done || true
  adb -s $deviceId shell ps | grep lldb-server | awk '{print $2}' | xargs adb -s $deviceId shell kill || true
  adb -s $deviceId shell rm -r $remoteDir || true
}
trap clean EXIT

set -x
adb -s $deviceId shell getprop ro.build.fingerprint
api=$(adb -s $deviceId shell getprop ro.build.version.sdk)
if [ "$api" -ge 26 ]; then
  adb -s $deviceId shell killall -KILL lldb-server || true
else
  adb -s $deviceId shell ps | grep lldb-server | awk '{print $2}' | xargs adb -s $deviceId shell kill || true
fi
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

dotest_args=()
dotest_args+=(-A "$arch")
dotest_args+=(-C "$ANDROID_NDK_HOME/toolchains/$toolchain/prebuilt/$host-x86_64/bin/$compiler")
dotest_args+=(-v -s "logs-$compiler-$arch-$deviceId" -u CXXFLAGS -u CFLAGS)
dotest_args+=(--platform-name remote-android)
dotest_args+=(--platform-url "$connect_url")
dotest_args+=(--platform-working-dir "$remoteDir")
appendCommonArgs

"$lldbDir/test/dotest.py" "${dotest_args[@]}"
