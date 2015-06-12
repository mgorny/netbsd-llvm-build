#!/bin/bash -ex

# $0 == external/lldb-utils/build-darwin.sh
ROOT=$(dirname $(dirname $(dirname $(realpath "$0"))))
cd "$ROOT"

if [ -h external/llvm/tools/clang ]; then
    rm external/llvm/tools/clang
fi
if [ -h external/llvm/tools/lldb ]; then
    rm external/llvm/tools/lldb
fi

ln -s ../../clang external/llvm/tools/clang
ln -s ../../lldb external/llvm/tools/lldb

CONFIG=Release
PRE=$ROOT/prebuilts
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH="$PRE/ninja/linux-x86:$PATH"
BUILD=$ROOT/out/lldb/host
rm -rf $BUILD
mkdir -p $BUILD
cd $BUILD
LLDB_FLAGS="-fuse-ld=gold -target x86_64-unknown-linux"
CLANG=$PRE/clang/linux-x86/host/3.6/bin/clang
export SWIG_LIB=$PRE/swig/linux-x86/share/swig/2.0.11/
$PRE/cmake/linux-x86/bin/cmake -G Ninja -DCMAKE_BUILD_TYPE=$CONFIG -DCMAKE_C_COMPILER="$CLANG"  -DCMAKE_CXX_COMPILER="$CLANG++" -DCMAKE_C_FLAGS="$LLDB_FLAGS" -DCMAKE_CXX_FLAGS="$LLDB_FLAGS" -DSWIG_EXECUTABLE=$PRE/swig/linux-x86/bin/swig $ROOT/external/llvm
$PRE/ninja/linux-x86/ninja
$PRE/ninja/linux-x86/ninja check-lldb

