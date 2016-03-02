#!/usr/bin/env bash
set -e
set -x
host=$(uname)
if [[ $host == Darwin ]];
then
  echo "Skip cmake step for" $host
else
  source setEnv.sh
  mkdir -p $buildDir
  cd $buildDir
  if [[ $host == NetBSD ]];
  then
    if [ -f /usr/include/panel.h ]; then
      cmake -GNinja -DCMAKE_BUILD_TYPE=Release $llvmDir -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -DLLDB_DISABLE_CURSES:BOOL=FALSE
    else
      cmake -GNinja -DCMAKE_BUILD_TYPE=Release $llvmDir -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -DLLDB_DISABLE_CURSES:BOOL=TRUE
    fi
  else
    cmake -GNinja -DCMAKE_BUILD_TYPE=Release $llvmDir -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++
  fi
fi
