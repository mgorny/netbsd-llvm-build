#!/bin/bash
# latest version of this file can be found at
# https://android.googlesource.com/platform/external/lldb-utils
#
# inputs
# $PROJECT - project name
# $MSVS - Visual Studio version
# $1 - (temporary) output directory
# $2 - destination directory for build artifacts
# $3 - build number
#
# this file does the following:
#
# 1) define the following env vars
#    OS - linux|darwin|windows
#    CORES - numer of cores (for parallel builds)
#    CC/CXX/LD
#    CFLAGS/CXXFLAGS/LDFLAGS
#    BUILD - build directory
#    INSTALL - install directory
#
# after placing all your build products into $INSTALL you should call
# finalize_build to produce the final build artifact

# exit on error
set -e

# calculate the root directory from the script path
# this script lives three directories down from the root
# external/lldb-utils/prebuilts/build-common.sh
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
cd "$ROOT_DIR"

function die() {
	echo "$*" > /dev/stderr
	echo "Usage: $0 <out_dir> <dest_dir> <build_number>" > /dev/stderr
	exit 1
}

(($# > 3)) && die "[$0] Unknown parameter: $4"

OUT="$1"
DEST="$2"
BNUM="$3"

[ ! "$OUT"  ] && die "## Error: Missing out folder"
[ ! "$DEST" ] && die "## Error: Missing destination folder"
[ ! "$BNUM" ] && die "## Error: Missing build number"

mkdir -p "$OUT" "$DEST"
OUT=$(cd "$OUT" && pwd -P)
DEST=$(cd "$DEST" && pwd -P)

cat <<END_INFO
## Building $PROJECT ##
## Out Dir  : $OUT
## Dest Dir : $DEST
## Build Num: $BNUM

END_INFO

unset DEPENDENCIES
LLDB_UTILS=$ROOT_DIR/external/lldb-utils
DEPENDENCIES+=("$LLDB_UTILS")

EXTERNAL=$ROOT_DIR/external
PREBUILTS=$ROOT_DIR/prebuilts
SOURCE=$EXTERNAL/$PROJECT
DEPENDENCIES+=("$SOURCE")

BUILD=$OUT/$PROJECT/build
INSTALL=$OUT/$PROJECT/install
rm -rf "$BUILD" "$INSTALL"
mkdir -p "$BUILD" "$INSTALL"

case "$(uname)" in
	Linux)
		OS=linux
		CORES=$(nproc)

		TOOLCHAIN=$PREBUILTS/gcc/linux-x86/host/x86_64-linux-glibc2.15-4.8
		find "$TOOLCHAIN" -name x86_64-linux -exec ln -fns {} {}-gnu \;

		CLANG=$PREBUILTS/clang/linux-x86/host/3.6
		export CC=$CLANG/bin/clang
		export CXX=$CC++
		export LD=$TOOLCHAIN/bin/x86_64-linux-ld

		unset FLAGS
		FLAGS+=(-fuse-ld=gold)
		FLAGS+=(--gcc-toolchain="$TOOLCHAIN")
		FLAGS+=(--sysroot "$TOOLCHAIN/sysroot")
		FLAGS+=(-B"$TOOLCHAIN/bin/x86_64-linux-")
		FLAGS+=(-m64)
		export CFLAGS="${FLAGS[*]} $CFLAGS"
		export CXXFLAGS="${FLAGS[*]} $CXXFLAGS"
		export LDFLAGS="${FLAGS[*]} $LDFLAGS"

		DEPENDENCIES+=("$TOOLCHAIN")
		DEPENDENCIES+=("$CLANG")
		;;
	Darwin)
		OS=darwin
		CORES=$(sysctl -n hw.ncpu)

		export CC=clang
		export CXX=clang++

		unset FLAGS
		FLAGS+=(-mmacosx-version-min=10.8)

		export CFLAGS="${FLAGS[*]} $CFLAGS"
		export CXXFLAGS="${FLAGS[*]} -stdlib=libc++ $CXXFLAGS"
		export LDFLAGS="${FLAGS[*]} $LDFLAGS"

		function fix_install_name() {
			for LIB in "$INSTALL"/lib/*.dylib; do
				# skip symlinks
				if [ -L "$LIB" ]; then
					continue
				fi
				ABSOLUTE=/lib/$(basename "$LIB")
				RELATIVE=@executable_path/../lib/$(basename "$LIB")
				install_name_tool -id "$RELATIVE" "$LIB"
				for TARGET in "$INSTALL"/{bin/*,lib/*.dylib}; do
					# skip symlinks and non Mach-O files
					if [ -L "$TARGET" ] || ! file "$TARGET" | grep Mach-O; then
						continue
					fi
					install_name_tool -change "$ABSOLUTE" "$RELATIVE" "$TARGET"
				done
			done
		}
		;;
	CYGWIN_NT-*)
		OS=windows
		CORES=$NUMBER_OF_PROCESSORS

		case "$MSVS" in
			2013)
				VS_DEV_CMD=${VS120COMNTOOLS}VsDevCmd.bat
				;;
			2015)
				VS_DEV_CMD=${VS140COMNTOOLS}VsDevCmd.bat
				;;
		esac

		function devenv() {
			cmd /c "$VS_DEV_CMD" '&' devenv.com "$@"
		}
		;;
esac

PATCHES=$LLDB_UTILS/prebuilts/patches/$PROJECT/$OS
if [ -d "$PATCHES" ]; then
	git -C "$SOURCE" apply "$PATCHES"/*.patch
fi

function finalize_build() {

	URL_PREFIX=https://android.googlesource.com/platform

	for DEPENDENCY in "${DEPENDENCIES[@]}"; do
		REVISION=$(git -C "$DEPENDENCY" rev-parse HEAD)
		cat >> "$INSTALL/revisions" <<-EOF
			$URL_PREFIX/${DEPENDENCY#$ROOT_DIR/}/+/$REVISION
		EOF
	done

	case "$OS" in
		linux)
			find "$TOOLCHAIN" -name x86_64-linux-gnu -type l -delete
			;;
		darwin)
			cat >> "$INSTALL/revisions" <<-EOF

				$(xcodebuild -version)
			EOF
			;;
		windows)
			cat >> "$INSTALL/revisions" <<-EOF
				$(devenv /? | head -2)
			EOF
	esac

	pushd "$INSTALL"
	zip --filesync --recurse-paths --symlinks "$DEST/$PROJECT-$OS-$BNUM.zip" .
	popd
}
