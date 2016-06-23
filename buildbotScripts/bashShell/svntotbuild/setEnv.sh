#!/usr/bin/env bash
set -e
ulimit -c unlimited
export originalDir=$(pwd)
export rootDir=$(pwd)/..
export buildDir=$rootDir/build
export remoteDir=/data/local/tmp/lldb

dataRoot=""
if [ ! -d "/lldb-buildbot" ]; then #check whether the build server has lldb-buildbot
  dataRoot=$HOME
else
  dataRoot="/lldb-buildbot"
fi
echo "DATAROOT"$dataRoot

export toolchain=$dataRoot/Toolchains_latest
export sdkDir=$dataRoot/Sdk

export port=5430
export gstrace=gs://lldb_test_traces
export gsbinaries=gs://lldb_binaries
export llvmDir=$rootDir/llvm
export lldbDir=$llvmDir/tools/lldb
export clangDir=$llvmDir/tools/clang
export lockDir=/var/tmp/lldbbuild.exclusivelock
export TMPDIR=$rootDir/tmp/
mkdir -p $TMPDIR
