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
  DESTDIR=$buildDir/install/android-$1 \
    cmake -DCMAKE_INSTALL_COMPONENT=lldb-server -DCMAKE_INSTALL_DO_STRIP=ON -P cmake_install.cmake
}

markBuildIncomplete
cmakenbuild i386
cmakenbuild x86_64
cmakenbuild arm
cmakenbuild aarch64
markBuildComplete
