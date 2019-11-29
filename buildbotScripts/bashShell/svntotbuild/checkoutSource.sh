#!/usr/bin/env bash
set -e
source setEnv.sh
source cleanUp.sh

maybeCleanUp

export monogit=https://github.com/llvm/llvm-project

if [ "$1" == "" ]; then
    export rev=origin/master
else
    export rev=$1
fi

makesym() {
  ln -f -s "$1" "$2"
}

if [ -d $projDir/.git ]; then
  (cd $projDir; git fetch)
else
  git clone $monogit $projDir
fi
(cd $projDir; git checkout "$rev")

makesym ../../lldb $llvmDir/tools/lldb
makesym ../../lld $llvmDir/tools/lld
makesym ../../clang $llvmDir/tools/clang
makesym ../../clang-tools-extra $llvmDir/tools/clang/tools/extra
makesym ../../polly $llvmDir/tools/polly
rm -f $llvmDir/projects/libunwind
rm -f $llvmDir/projects/libcxxabi
rm -f $llvmDir/projects/libcxx
rm -f $llvmDir/projects/openmp
rm -f $llvmDir/projects/compiler-rt
