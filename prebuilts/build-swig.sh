#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

PROJECT=swig

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
source "$SCRIPT_DIR/build-common.sh" "$@"

set -e -x
PCRE=$EXTERNAL/pcre
DEPENDENCIES+=("$PCRE")

git -C "$PCRE" archive @:dist \
	--format=tar --prefix=pcre-git/ -o "$BUILD/pcre-git.tar"

pushd "$BUILD"
"$SOURCE/Tools/pcre-build.sh"
"$SOURCE/configure" --prefix=
make -j"$CORES"
# install-ccache fails on OS X
make DESTDIR="$INSTALL" install-main install-lib
popd

ln -fns swig "$INSTALL/bin/swig2.0"

finalize_build
