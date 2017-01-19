#!/usr/bin/env bash
set -e
source setEnv.sh
source cleanUp.sh

set -x

function cmakenbuild {
  dir=$buildDir/android-$1
  mkdir -p $dir && cd $dir
  cmake -C "$originalDir/lldb-utils/config/android-$1.cmake" "$llvmDir"
  nice ninja lldb-server
}

markBuildIncomplete
cmakenbuild i386
cmakenbuild x86_64
cmakenbuild arm
cmakenbuild aarch64
cmakenbuild mips
cmakenbuild mips64
markBuildComplete
