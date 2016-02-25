#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

PROJECT=ninja
MSVS=2015

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
source "$SCRIPT_DIR/build-common.sh" "$@"

set -x

pushd "$BUILD"

PYTHON_DIR=$PREBUILTS/python/$OS-x86
DEPENDENCIES+=("$PYTHON_DIR")

case "$OS" in
	windows)
		cat > "$BUILD/commands.bat" <<-EOF
		set PATH=C:\\Windows\\System32
		call "$VS_DEV_CMD"
		set SOURCE=$(cygpath --windows "$SOURCE")
		set PYTHON=$(cygpath --windows "$PYTHON_DIR/x86/python.exe")
		%PYTHON% %SOURCE%\\configure.py --bootstrap --platform=msvc
		EOF
		cmd /c "$(cygpath --windows "$BUILD/commands.bat")"
		;;
	*)
		PYTHON=$PYTHON_DIR/bin/python
		"$PYTHON" "$SOURCE/configure.py" --bootstrap
		;;
esac

install ninja "$INSTALL"
popd

finalize_build
