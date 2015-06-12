#!/bin/bash -ex
# OSX lacks a "realpath" bash command
realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

# $0 == external/lldb-utils/build-darwin.sh
ROOT=$(dirname $(dirname $(dirname $(realpath "$0"))))

# OUT isn't used yet
OUT=$(realpath "$1")

if [ ! -f external/llvm/tools/clang ]; then
    ln -s ../../clang external/llvm/tools/clang
fi
if [ ! -f external/lldb/llvm ]; then
    ln -s ../llvm external/lldb/llvm
fi

CONFIG=Release
PRE=$ROOT/prebuilts
export PATH="$PRE/swig/darwin-x86/bin:$PATH"
export SWIG_LIB=$PRE/swig/darwin-x86/share/swig/2.0.11/
cd $ROOT/external/lldb
xcodebuild -configuration $CONFIG -target desktop
cd $ROOT/external/lldb/test
./dosep.py
