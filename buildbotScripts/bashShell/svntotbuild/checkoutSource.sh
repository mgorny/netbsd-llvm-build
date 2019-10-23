#!/usr/bin/env bash
set -e
source setEnv.sh
source cleanUp.sh

maybeCleanUp

export monogit=https://github.com/llvm/llvm-project

if [ "$1" == "" ]; then
    export rev=HEAD
else
    export rev=$1
fi

makesym() {
  if ! [ -h "$2" ]; then
    ln -s "$1" "$2"
  fi
}

if [ -d $rootDir/.git ]; then
  git pull
else
  git clone $monogit $rootDir
fi

makesym ../../lldb $llvmDir/tools/lldb
makesym ../../lld $llvmDir/tools/lld
makesym ../../clang $llvmDir/tools/clang
makesym ../../../../clang-tools-extra $llvmDir/tools/clang/tools/extra
makesym ../../polly $llvmDir/tools/polly
makesym ../../test-suite $llvmDir/projects/test-suite
makesym ../../libunwind $llvmDir/projects/libunwind
makesym ../../libcxxabi $llvmDir/projects/libcxxabi
makesym ../../libcxx $llvmDir/projects/libcxx
makesym ../../openmp $llvmDir/projects/openmp
