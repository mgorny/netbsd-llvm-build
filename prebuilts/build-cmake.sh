#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

PROJECT=cmake
MSVS=2013

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
source "$SCRIPT_DIR/build-common.sh" "$@"

set -x

case "$OS" in
windows)
	CMAKE_DIR=$PREBUILTS/cmake/windows-x86
	DEPENDENCIES+=("$CMAKE_DIR")
	cat > "$BUILD/commands.bat" <<-EOF
		set PATH=C:\\Windows\\System32
		call "$VS_DEV_CMD"
		set SOURCE=$(cygpath --windows "$SOURCE")
		set BUILD=$(cygpath --windows "$BUILD")
		set INSTALL=$(cygpath --windows "$INSTALL")
		set CMAKE=$(cygpath --windows "$CMAKE_DIR/bin/cmake.exe")
		"%CMAKE%" -H"%SOURCE%" -B"%BUILD%" -DCMAKE_INSTALL_PREFIX="%INSTALL%"
		"%CMAKE%" --build "%BUILD%" --target Release
		"%CMAKE%" --build "%BUILD%" --target install
	EOF
	cmd /c "$(cygpath --windows "$BUILD/commands.bat")"
	;;
*)
	pushd "$BUILD"
	"$SOURCE/configure" --prefix=
	make -j"$CORES"
	make DESTDIR="$INSTALL" install/strip
	popd
	;;
esac

finalize_build
