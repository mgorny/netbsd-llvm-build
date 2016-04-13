#!/bin/bash
export originalDir=$(pwd)
export rootDir=$(pwd)/..
export lldbDir=$rootDir/lldb
export buildDir=$rootDir/build
export remoteDir=/data/local/tmp/lldb
export toolchain=$HOME/Toolchains_r11c
export gstrace=gs://lldb_test_traces_asbuild
export port=5430
if [ $(uname) == Darwin ]
then
  export DYLD_FRAMEWORK_PATH=$lldbDir/build/Release
fi
export lockDir=/var/tmp/lldbbuild.exclusivelock
