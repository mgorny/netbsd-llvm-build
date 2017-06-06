#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

PROJECT=libedit

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
source "$SCRIPT_DIR/build-common.sh" "$@"

set -x

if [ "$OS" == windows ]; then
  exit 0
fi

pushd "$BUILD"

# Avoid autoconf dependency
#
# git doesn't preserve timestamps (for good reason) and libedit build is set up
# in a way that it will attempt to regenerate configure files, which will fail
# if we don't have autoconf installed.
# There's no reason to do this as we have not modified the files, so just touch
# them in the correct dependency sequence to avoid this.
touch "$SOURCE"/{configure.ac,acinclude.m4}
sleep 2
touch "$SOURCE"/aclocal.m4
sleep 2
touch "$SOURCE"/{.,doc,examples,src}/Makefile.in
sleep 2
touch "$SOURCE"/{configure,config.h.in}

# libtool doesn't pass CFLAGS to link command
"$SOURCE/configure" --prefix= CC="$CC $CFLAGS" CFLAGS=


make -j"$CORES"
make DESTDIR="$INSTALL" install-strip
popd

if [ "$OS" == darwin ]; then
	fix_install_name
fi

finalize_build
