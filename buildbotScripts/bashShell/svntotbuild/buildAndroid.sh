#!/usr/bin/env bash
set -e
source setEnv.sh
source cleanUp.sh

function androidMake {
if [[ $1 == mips* ]]
then
  triple=$1el
else
  triple=$1
fi
  cmake -GNinja -DCMAKE_BUILD_TYPE=MinSizeRel $llvmDir \
-DCMAKE_TOOLCHAIN_FILE=$lldbDir/cmake/platforms/Android.cmake \
-DANDROID_TOOLCHAIN_DIR=$toolchain/$1-21 \
-DANDROID_ABI=$2 \
-DCMAKE_CXX_COMPILER_VERSION=4.9 \
-DLLVM_TARGET_ARCH=$1 \
-DLLVM_HOST_TRIPLE=$triple-unknown-linux-android \
-DLLVM_TABLEGEN=$buildDir/bin/llvm-tblgen \
-DCLANG_TABLEGEN=$buildDir/bin/clang-tblgen
}

function build {
  nice -n 10 ninja -j40 lldb-server
}

function cmakenbuild {
  dir=$buildDir/android-$1
  mkdir -p $dir && cd $dir
  androidMake $1 $2
  build
}
set -x
markBuildIncomplete
cmakenbuild i386 x86
cmakenbuild x86_64 x86_64
cmakenbuild arm armeabi
cmakenbuild aarch64 aarch64
cmakenbuild mips mips
cmakenbuild mips64 mips64
markBuildComplete
