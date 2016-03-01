#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

OS=linux

LLDB_UTILS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
source "$LLDB_UTILS/build-common.sh" "$@"

export PATH=/usr/bin:/bin

CONFIG=Release

unset LLDB_FLAGS
unset LLDB_LINKER_FLAGS
unset CMAKE_OPTIONS

CC=$PREBUILTS/clang/linux-x86/host/3.6/bin/clang
TOOLCHAIN=$PREBUILTS/gcc/linux-x86/host/x86_64-linux-glibc2.15-4.8

LLDB_FLAGS+=(-fuse-ld=gold)
LLDB_FLAGS+=(-target x86_64-unknown-linux)
LLDB_FLAGS+=(--gcc-toolchain="$TOOLCHAIN")
LLDB_FLAGS+=(--sysroot="$TOOLCHAIN/sysroot")
LLDB_FLAGS+=(-B"$TOOLCHAIN/bin/x86_64-linux-")
LLDB_FLAGS+=(-I"$PREBUILTS/libedit/linux-x86/include")

LLDB_LINKER_FLAGS+=(-L"$PREBUILTS/libedit/linux-x86/lib")

CMAKE_OPTIONS+=(-GNinja)
CMAKE_OPTIONS+=(-H"$LLVM")
CMAKE_OPTIONS+=(-B"$BUILD")
CMAKE_OPTIONS+=(-DCMAKE_MAKE_PROGRAM="$NINJA")
CMAKE_OPTIONS+=(-DCMAKE_BUILD_TYPE=$CONFIG)
CMAKE_OPTIONS+=(-DCMAKE_C_COMPILER="$CC")
CMAKE_OPTIONS+=(-DCMAKE_CXX_COMPILER="$CC++")
CMAKE_OPTIONS+=(-DCMAKE_AR="$TOOLCHAIN/bin/x86_64-linux-ar")
CMAKE_OPTIONS+=(-DCMAKE_C_FLAGS="${LLDB_FLAGS[*]}")
CMAKE_OPTIONS+=(-DCMAKE_CXX_FLAGS="${LLDB_FLAGS[*]}")
CMAKE_OPTIONS+=(-DCMAKE_EXE_LINKER_FLAGS="${LLDB_LINKER_FLAGS[*]}")
CMAKE_OPTIONS+=(-DCMAKE_MODULE_LINKER_FLAGS="${LLDB_LINKER_FLAGS[*]}")
CMAKE_OPTIONS+=(-DCMAKE_SHARED_LINKER_FLAGS="${LLDB_LINKER_FLAGS[*]}")
CMAKE_OPTIONS+=(-DLLDB_DISABLE_CURSES=1)
CMAKE_OPTIONS+=(-DSWIG_EXECUTABLE="$SWIG_DIR/bin/swig")
CMAKE_OPTIONS+=(-DPYTHON_EXECUTABLE="$PYTHON_DIR/bin/python")
CMAKE_OPTIONS+=(-DPYTHON_LIBRARY="$PYTHON_DIR/lib/libpython2.7.so")
CMAKE_OPTIONS+=(-DPYTHON_INCLUDE_DIR="$PYTHON_DIR/include/python2.7")
CMAKE_OPTIONS+=(-DLLVM_TARGETS_TO_BUILD="X86;ARM;AArch64;Mips;Hexagon")
CMAKE_OPTIONS+=(-DCMAKE_INSTALL_PREFIX=)
CMAKE_OPTIONS+=(-DLLVM_EXTERNAL_LLDB_SOURCE_DIR="$LLDB")
CMAKE_OPTIONS+=(-DLLVM_EXTERNAL_CLANG_SOURCE_DIR="$CLANG")

# Necessary because clang recognizes x86_64-linux-gnu
# as a valid gcc toolchain but not x86_64-linux.
find "$TOOLCHAIN" -name x86_64-linux -exec ln -fns {} {}-gnu \;

"$CMAKE" "${CMAKE_OPTIONS[@]}"
for TARGET in lldb lldb-server finish_swig lib/readline.so; do
	"$CMAKE" --build "$BUILD" --target "$TARGET"
done

# install target builds/installs 5G of stuff we don't need
#DESTDIR="$INSTALL/host" "$CMAKE" --build "$BUILD" --target install

find "$TOOLCHAIN" -name x86_64-linux-gnu -type l -delete

mkdir -p "$INSTALL/host/"{bin,lib,include/lldb}
cp -a "$BUILD/bin/"lldb*                             "$INSTALL/host/bin/"
cp -a "$PYTHON_DIR/bin/"python*                      "$INSTALL/host/bin/"
cp -a "$BUILD/lib/"{liblldb.so*,readline.so}         "$INSTALL/host/lib/"
cp -a "$PREBUILTS/libedit/linux-x86/lib/"libedit.so* "$INSTALL/host/lib/"
cp -a "$TOOLCHAIN/sysroot/usr/lib/"libtinfo.so*      "$INSTALL/host/lib/"
cp -a "$PYTHON_DIR/lib/"{libpython2.7.so*,python2.7} "$INSTALL/host/lib/"
cp -a "$BUILD/lib/python2.7/site-packages"           "$INSTALL/host/lib/python2.7"
cp -a "$LLDB/include/lldb/"{API,Utility,lldb-*.h}    "$INSTALL/host/include/lldb/"

find "$INSTALL/host/include/lldb" -name 'lldb-private*.h' -delete

unset PRUNE
PRUNE+=(-name '*.pyc')
PRUNE+=(-or -name '*.pyo')
PRUNE+=(-or -name 'plat-*')
PRUNE+=(-or -name 'config')
PRUNE+=(-or -name 'idlelib')
PRUNE+=(-or -name 'lib2to3')
PRUNE+=(-or -name 'test')
find "$INSTALL/host/lib/python2.7" '(' "${PRUNE[@]}" ')' -prune -exec rm -r {} +

pushd "$INSTALL/host"
zip --filesync --recurse-paths --symlinks "$DEST/lldb-linux-$BNUM.zip" .
popd
