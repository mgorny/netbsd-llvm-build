#!/bin/bash
# Expected arguments:
# $1 = out_dir
# $2 = dest_dir
# $3 = build_number

OS=darwin

LLDB_UTILS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
source "$LLDB_UTILS/build-common.sh" "$@"

ln -fns "$LLVM" "$LLDB/"
ln -fns "$CLANG" "$LLVM/tools/"

export PATH=$NINJA_DIR:$CMAKE_DIR/bin:$SWIG_DIR/bin:/usr/sbin:/usr/bin:/bin

# we don't need code signing
function codesign() { :; }
export -f codesign

CONFIG=Release

unset XCODEBUILD_OPTIONS
unset PRUNE

XCODEBUILD_OPTIONS+=(-project "$LLDB/lldb.xcodeproj")
XCODEBUILD_OPTIONS+=(-configuration "$CONFIG")
XCODEBUILD_OPTIONS+=(-target desktop)
XCODEBUILD_OPTIONS+=(OBJROOT="$BUILD")
XCODEBUILD_OPTIONS+=(SYMROOT="$BUILD")

xcodebuild "${XCODEBUILD_OPTIONS[@]}"

mkdir -p "$INSTALL/host/include/lldb"
cp -a "$BUILD/$CONFIG/"{lldb,LLDB.framework}      "$INSTALL/host/"
cp -a "$LLDB/include/lldb/"{API,Utility,lldb-*.h} "$INSTALL/host/include/lldb/"

find "$INSTALL/host/include/lldb" -name 'lldb-private*.h' -delete

unset PRUNE
PRUNE+=('(' -name Clang -and -type d ')')
PRUNE+=( -or -name argdumper)
PRUNE+=( -or -name darwin-debug)
PRUNE+=( -or -name lldb-server)

# zip file is huge, need to prune
find "$INSTALL/host/LLDB.framework" '(' "${PRUNE[@]}" ')' -exec rm -rf {} +

pushd "$INSTALL/host"
zip --filesync --recurse-paths --symlinks "$DEST/lldb-mac-$BNUM.zip" .
popd
