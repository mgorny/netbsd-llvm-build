# latest version of this file can be found at
# https://android.googlesource.com/platform/external/lldb-utils
#
# inputs
# $PROJ - project name
# $VER - project version
# $1 - (temporary) output directory
# $2 - build directory for build artefacts
# $3 - build number
#
# this file does the following:
#
# 1) define the following env vars
#    OS - linux|darwin|windows
#    CORES - numer of cores (for parallel builds)
#    PATH (with appropriate compilers)
#    CFLAGS/CXXFLAGS/LDFLAGS
#    RD - root directory for source and object files
#    INSTALL - install directory
#    SCRIPT_FILE - absolute path to the parent build script
#    SCRIPT_DIR - absolute path to the parent build script's directory
#    COMMON_FILE - absolute path to this file
# 2) cd $RD
#
# after placing all your build products into $INSTALL you should call finalize_build to produce
# the final build artifact

# exit on error
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd -P)"
SCRIPT_FILE="$SCRIPT_DIR/$(basename "${BASH_SOURCE[1]}")"
COMMON_FILE="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"

# calculate the root directory from the script path
# this script lives two directories down from the root
# external/lldb-utils/prebuilts/build-common.sh
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
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
OUT="$(cd "$OUT" && pwd -P)"
DEST="$(cd "$DEST" && pwd -P)"

cat <<END_INFO
## Building $PROJ ##
## Out Dir  : $OUT
## Dest Dir : $DEST
## Build Num: $BNUM

END_INFO

UNAME="$(uname)"
UPSTREAM=https://android.googlesource.com/platform/prebuilts
case "$UNAME" in
Linux)
    OS='linux'
    INSTALL_VER=$VER
    ;;
Darwin)
    OS='darwin'
    OSX_MIN=10.8
    export CC=clang
    export CXX=$CC++
    export CFLAGS="$CFLAGS -mmacosx-version-min=$OSX_MIN"
    export CXXFLAGS="$CXXFLAGS -mmacosx-version-min=$OSX_MIN -stdlib=libc++"
    export LDFLAGS="$LDFLAGS -mmacosx-version-min=$OSX_MIN"
    INSTALL_VER=$VER
    ;;
*_NT-*)
    OS='windows'
    CORES=$NUMBER_OF_PROCESSORS
    # VS2013 x64 Native Tools Command Prompt
    case "$MSVS" in
    2013)
        devenv() {
            cmd /c "${VS120COMNTOOLS}VsDevCmd.bat" '&' devenv.com "$@"
        }
        INSTALL_VER=${VER}_${MSVS}
        ;;
    *)
        # g++/make build
        export CC=x86_64-w64-mingw32-gcc
        export CXX=x86_64-w64-mingw32-g++
        export LD=x86_64-w64-mingw32-ld
        ;;
    esac
    ;;
*)
    exit 1
    ;;
esac

RD=$OUT/$PROJ
INSTALL="$RD/install"

cd /tmp # windows can't delete if you're in the dir
rm -rf $RD
mkdir -p $INSTALL
mkdir -p $RD
cd $RD

# clone prebuilt gcc
case "$OS" in
linux)
    # can't get prebuilt clang working so we're using host clang-3.5 https://b/22748915
    #CLANG_DIR=$RD/clang
    #git clone $UPSTREAM/clang/linux-x86/host/3.6 $CLANG_DIR
    #export CC="$CLANG_DIR/bin/clang"
    #export CXX="$CC++"
    export CC=clang-3.5
    export CXX=clang++-3.5

    GCC_DIR=$RD/gcc
    git clone $UPSTREAM/gcc/linux-x86/host/x86_64-linux-glibc2.15-4.8 $GCC_DIR

    find "$GCC_DIR" -name x86_64-linux -exec ln -fns {} {}-gnu \;

    FLAGS+=(-fuse-ld=gold)
    FLAGS+=(--gcc-toolchain="$GCC_DIR")
    FLAGS+=(--sysroot "$GCC_DIR/sysroot")
    FLAGS+=(-B"$GCC_DIR/bin/x86_64-linux-")
    export CFLAGS="$CFLAGS ${FLAGS[*]}"
    export CXXFLAGS="$CXXFLAGS ${FLAGS[*]}"
    export LDFLAGS="$LDFLAGS -m64"
    ;;
esac

function finalize_build() {
    cp "$SCRIPT_FILE" "$COMMON_FILE" "$INSTALL"
    (cd "$INSTALL" && zip --symlinks -r "$DEST/$PROJ-$BNUM.zip" .)
}
