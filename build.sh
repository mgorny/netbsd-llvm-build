#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

case "$(uname)" in
	Linux)  OS=linux;;
	Darwin) OS=darwin;;
	CYGWIN_NT-*) OS=windows;;
esac

LLDB_UTILS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

source "$LLDB_UTILS/build-$OS.sh" "$@"

if [ $OS == linux ]; then
	source "$LLDB_UTILS/build-android.sh" "$@"

	pushd "$LLDB"
	zip --symlinks -r "$DEST/lldb-tests-$BNUM.zip" test packages resources
	popd
fi
