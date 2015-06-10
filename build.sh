ROOT=$(pwd)
export PATH=$PATH:$ROOT/clang/bin

ln -s ../../clang llvm/tools/clang
ln -s ../../lldb llvm/tools/lldb

CONFIG=Release
PRE=$ROOT/prebuilts
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
BUILD=$ROOT/out/host
rm -rf $BUILD
mkdir -p $BUILD
cd $BUILD
LLDB_FLAGS="-fuse-ld=gold -target x86_64-unknown-linux"
CLANG=$PRE/clang/linux-x86/bin/clang
export SWIG_LIB=$PRE/swig/linux-x86/share/swig/2.0.11/
$PRE/cmake/linux-x86/bin/cmake -G Ninja -DCMAKE_BUILD_TYPE=$CONFIG -DCMAKE_C_COMPILER="$CLANG"  -DCMAKE_CXX_COMPILER="$CLANG++" -DCMAKE_C_FLAGS="$LLDB_FLAGS" -DCMAKE_CXX_FLAGS="$LLDB_FLAGS" -DSWIG_EXECUTABLE=$PRE/swig/linux-x86/bin/swig $ROOT/llvm
$PRE/ninja/linux-x86/ninja
$PRE/ninja/linux-x86/ninja check-lldb

