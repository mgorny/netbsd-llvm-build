#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

case "$(uname)" in
	Linux)  OS=linux;;
	Darwin) OS=darwin;;
	*)	echo "Unknown OS" >&2; exit 1;;
esac

LLDB_UTILS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
source "$LLDB_UTILS/build-common.sh" "$@"

export PATH=/usr/bin:/bin

unset CMAKE_OPTIONS
unset CMAKE_TARGETS

CMAKE_TARGETS+=(lldb)
CMAKE_OPTIONS+=(-C"$LLDB_UTILS/config/$OS.cmake")
CMAKE_OPTIONS+=(-H"$LLVM")
CMAKE_OPTIONS+=(-B"$BUILD")


"$CMAKE" "${CMAKE_OPTIONS[@]}"
"$CMAKE" --build "$BUILD" --target lldb

# install target builds/installs 5G of stuff we don't need
#DESTDIR="$INSTALL/host" "$CMAKE" --build "$BUILD" --target install

mkdir -p "$INSTALL/host/"{bin,lib,include/lldb,include/LLDB}
cp -a "$BUILD/bin/"lldb*                             "$INSTALL/host/bin/"
if [ "$OS" == linux ]; then
	TOOLCHAIN=$PREBUILTS/gcc/linux-x86/host/x86_64-linux-glibc2.15-4.8

	cp -a "$PYTHON_DIR/bin/"python*                      "$INSTALL/host/bin/"
	cp -a "$BUILD/lib/"{liblldb.so*,readline.so}         "$INSTALL/host/lib/"
	cp -a "$PREBUILTS/libedit/linux-x86/lib/"libedit.so* "$INSTALL/host/lib/"
	cp -a "$TOOLCHAIN/sysroot/usr/lib/"libtinfo.so*      "$INSTALL/host/lib/"
	cp -a "$PYTHON_DIR/lib/"{libpython2.7.so*,python2.7} "$INSTALL/host/lib/"
else
	cp -a "$PREBUILTS/clang/host/$OS-x86/clang-$CLANG_VERSION/lib64/libc++.dylib" "$INSTALL/host/lib"
	cp -a "$BUILD/lib/"liblldb.*dylib                    "$INSTALL/host/lib/"
	mkdir "$INSTALL/host/lib/python2.7"
fi
cp -a "$BUILD/lib/python2.7/site-packages"           "$INSTALL/host/lib/python2.7"
cp -a "$LLDB/include/lldb/API/"*                     "$INSTALL/host/include/LLDB/"
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
zip --filesync --recurse-paths --symlinks "$DEST/lldb-$OS-$BNUM.zip" .
popd
