#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

PROJECT=libedit
URL_PREFIX=https://android.googlesource.com/platform

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
source "$SCRIPT_DIR/build-common.sh" "$@"

set -x

pushd "$BUILD"

# libtool doesn't pass CFLAGS to link command
"$SOURCE/configure" --prefix= CC="$CC $CFLAGS" CFLAGS=

# avoid needing aclocal-1.15
# configure modifies itself, which leads make into thinking that these need to
# be regenerated
touch "$SOURCE"/{aclocal.m4,configure.ac,Makefile.am,Makefile.in}

make -j"$CORES"
make DESTDIR="$INSTALL" install-strip
popd

if [ "$OS" == darwin ]; then
	fix_install_name
fi

finalize_build
