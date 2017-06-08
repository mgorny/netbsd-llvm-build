#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

case "$(uname)" in
	Linux|Darwin)	SCRIPT=posix;;
	CYGWIN_NT-*)	SCRIPT=windows;;
	*)		echo "Unknown OS" >&2; exit 1;;
esac

LLDB_UTILS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

source "$LLDB_UTILS/build-$SCRIPT.sh" "$@"

if [ "$(uname)" == Linux ]; then
	source "$LLDB_UTILS/build-android.sh" "$@"

	pushd "$LLDB"
	zip --symlinks -r "$DEST/lldb-tests-$BNUM.zip" test packages resources
	popd
fi
