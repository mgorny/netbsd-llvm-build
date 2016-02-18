#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

PROJECT=python
MSVS=2013

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
source "$SCRIPT_DIR/build-common.sh" "$@"

set -x

case "$OS" in
	windows)
		pushd "$SOURCE"
		cp PC/pyconfig.h Include/
		devenv PCbuild/pcbuild.sln /Upgrade
		for BUILD_TYPE in Debug Release "Debug^|x64" "Release^|x64"; do
			devenv PCbuild/pcbuild.sln /Build "$BUILD_TYPE"
		done
		python "$EXTERNAL/lldb/scripts/install_custom_python.py" \
			--source "$(cygpath --windows "$SOURCE")" \
			--dest "$(cygpath --windows "$INSTALL")" \
			--overwrite --silent
		popd
		;;
	*)
		pushd "$BUILD"
		if [ "$OS" == linux ]; then
			export LDFLAGS+=' -Wl,-rpath,\$$ORIGIN/../lib:\$$ORIGIN/../..'
		fi
		"$SOURCE/configure" --prefix= --enable-unicode=ucs4 --enable-shared
		make -j"$CORES"
		make DESTDIR="$INSTALL" install
		popd

		if [ "$OS" == darwin ]; then
			# dylib missing write permission, weird...
			chmod u+w "$INSTALL"/lib/*.dylib
			fix_install_name
		fi
		;;
esac

find "$INSTALL" '(' -name '*.pyc' -or -name '*.pyo' ')' -delete

cat > "$INSTALL/.gitignore" <<EOF
*.pyc
*.pyo
EOF

finalize_build
