#!/usr/bin/env bash
set -e
set -x

source setEnv.sh
buildType=Release
mkdir -p "$buildDir"
cd "$buildDir"
host=$(uname)
if [[ "$host" == NetBSD ]]; then
  if [ -f /usr/include/panel.h ]; then
    cmake -GNinja -DCMAKE_BUILD_TYPE="$buildType" "$llvmDir" -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -DLLDB_DISABLE_CURSES:BOOL=FALSE
  else
    cmake -GNinja -DCMAKE_BUILD_TYPE="$buildType" "$llvmDir" -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -DLLDB_DISABLE_CURSES:BOOL=TRUE
  fi
else
  cmake -GNinja -DCMAKE_BUILD_TYPE="$buildType" "$llvmDir" -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++
fi
