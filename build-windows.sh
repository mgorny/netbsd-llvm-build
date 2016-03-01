#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

OS=windows

LLDB_UTILS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
source "$LLDB_UTILS/build-common.sh" "$@"

# path too long
TMP=$(mktemp --directory)
mv "$LLVM" "$LLDB" "$CLANG" "$TMP/"
LLVM=$TMP/llvm
LLDB=$TMP/lldb
CLANG=$TMP/clang

function finish() {
	# make sure nothing's holding these open
	wait
	# move these back; ignoring failures
	mv "$LLVM" "$LLDB" "$CLANG" "$ROOT_DIR/external/" || true
	rm -rf "$TMP"
}

trap finish EXIT

export SWIG_LIB=$(cygpath --windows "$SWIG_LIB")

CONFIG=Release

unset CMAKE_OPTIONS
CMAKE_OPTIONS+=(-GNinja)
CMAKE_OPTIONS+=(-H"$(cygpath --windows "$LLVM")")
CMAKE_OPTIONS+=(-B"$(cygpath --windows "$BUILD")")
CMAKE_OPTIONS+=(-DCMAKE_MAKE_PROGRAM="$(cygpath --windows "$NINJA.exe")")
CMAKE_OPTIONS+=(-DCMAKE_BUILD_TYPE="$CONFIG")
CMAKE_OPTIONS+=(-DSWIG_DIR="$(cygpath --windows "$SWIG_DIR")")
CMAKE_OPTIONS+=(-DSWIG_EXECUTABLE="$(cygpath --windows "$SWIG_DIR/bin/swig.exe")")
CMAKE_OPTIONS+=(-DLLDB_RELOCATABLE_PYTHON=1)
CMAKE_OPTIONS+=(-DPYTHON_HOME="$(cygpath --windows "$PYTHON_DIR/x86")")
CMAKE_OPTIONS+=(-DLLVM_TARGETS_TO_BUILD="X86;ARM;AArch64;Mips;Hexagon")
CMAKE_OPTIONS+=(-DCMAKE_INSTALL_PREFIX="$(cygpath --windows "$INSTALL/host")")
CMAKE_OPTIONS+=(-DLLVM_EXTERNAL_LLDB_SOURCE_DIR="$(cygpath --windows "$LLDB")")
CMAKE_OPTIONS+=(-DLLVM_EXTERNAL_CLANG_SOURCE_DIR="$(cygpath --windows "$CLANG")")

cat > "$TMP/commands.bat" <<-EOF
	set PATH=C:\\Windows\\System32
	set CMAKE=$(cygpath --windows "${CMAKE}.exe")
	set BUILD=$(cygpath --windows "$BUILD")
	call "${VS120COMNTOOLS}VsDevCmd.bat"
	"%CMAKE%" $(printf '"%s" ' "${CMAKE_OPTIONS[@]}")
	"%CMAKE%" --build "%BUILD%" --target lldb
	"%CMAKE%" --build "%BUILD%" --target finish_swig
	@rem Too large and missing site-packages - http://llvm.org/pr24378
	@rem "%CMAKE%" --build "%BUILD%" --target install
EOF

cat "$TMP/commands.bat"
cmd /c "$(cygpath --windows "$TMP/commands.bat")"
rm "$TMP/commands.bat"

mkdir -p "$INSTALL/host/"{bin,lib,include/lldb,dlls}
cp -a "$BUILD/bin/"{lldb.exe,liblldb.dll}         "$INSTALL/host/bin/"
cp -a "$PYTHON_DIR/x86/"{python.exe,python27.dll} "$INSTALL/host/bin/"
cp -a "$BUILD/lib/"{liblldb.lib,site-packages}    "$INSTALL/host/lib/"
cp -a "$PYTHON_DIR/x86/Lib/"*                     "$INSTALL/host/lib/"
cp -a "$PYTHON_DIR/x86/DLLs/"*.pyd                "$INSTALL/host/dlls/"
cp -a "$LLDB/include/lldb/"{API,Utility,lldb-*.h} "$INSTALL/host/include/lldb/"

find "$INSTALL/host/include/lldb" -name 'lldb-private*.h' -delete

unset PRUNE
PRUNE+=(-name '*.pyc')
PRUNE+=(-or -name 'plat-*')
PRUNE+=(-or -name 'idlelib')
PRUNE+=(-or -name 'lib2to3')
PRUNE+=(-or -name 'test')
find "$INSTALL/host/lib/" '(' "${PRUNE[@]}" ')' -prune -exec rm -r {} +

pushd "$INSTALL/host"
zip --filesync --recurse-paths "$DEST/lldb-windows-$BNUM.zip" .
popd
