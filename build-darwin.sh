#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

# exit on error
set -e

# OS X lacks a "realpath" bash command
realpath() {
    [[ "$1" == /* ]] && echo "$1" || echo "$PWD/$1"
}

# calculate the root directory from the script path
# this script lives two directories down from the root
# external/lldb-utils/build-darwin.sh
ROOT_DIR="$(realpath "$(dirname "$0")/../..")"
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

OUT="$(realpath "$OUT")"
DEST="$(realpath "$DEST")"

cat <<END_INFO
## Building android-studio ##
## Out Dir  : $OUT
## Dest Dir : $DEST
## Build Num: $BNUM

END_INFO

LLVM="$ROOT_DIR/external/llvm"
LLDB="$ROOT_DIR/external/lldb"

ln -fns ../../clang "$LLVM/tools/clang"
ln -fns ../llvm "$LLDB/llvm"

PRE="$ROOT_DIR/prebuilts"

export PATH="$PRE/swig/darwin-x86/bin:/usr/sbin:/usr/bin:/bin"
export SWIG_LIB="$PRE/swig/darwin-x86/share/swig/2.0.11"

INSTALL="$OUT/lldb/install"
rm -rf "$INSTALL"

CONFIG=Release

BUILD="$OUT/lldb/host"
rm -rf "$BUILD"
mkdir -p "$BUILD"

unset XCODEBUILD_OPTIONS
unset PRUNE

XCODEBUILD_OPTIONS+=(-configuration $CONFIG)
XCODEBUILD_OPTIONS+=(-target desktop)
XCODEBUILD_OPTIONS+=(OBJROOT="$BUILD")
XCODEBUILD_OPTIONS+=(SYMROOT="$BUILD")

(cd "$LLDB" && xcodebuild "${XCODEBUILD_OPTIONS[@]}")

mkdir -p "$INSTALL/host" "$INSTALL/host/include/lldb"
cp -a "$BUILD/$CONFIG/"{lldb,LLDB.framework}      "$INSTALL/host/"
cp -a "$LLDB/include/lldb/"{API,Utility,lldb-*.h} "$INSTALL/host/include/lldb/"

find "$INSTALL/host/include/lldb" -name 'lldb-private*.h' -exec rm {} +

PRUNE+=('(' -name Clang -and -type d ')')
PRUNE+=( -or -name argdumper)
PRUNE+=( -or -name darwin-debug)
PRUNE+=( -or -name lldb-server)

# zip file is huge, need to prune
find "$INSTALL/host/LLDB.framework" '(' "${PRUNE[@]}" ')' -exec rm -rf {} +

mkdir -p "$DEST"
(cd "$INSTALL/host" && zip -r --symlinks "$DEST/lldb-mac-${BNUM}.zip" .)