#!/usr/bin/env bash

# Do not generate any output from this file. It is sourced from files (getRevision.sh) that need
# a clean output stream.

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

export ANDROID_NDK_HOME=$dataRoot/android-ndk-r17
export port=5430
export gstrace=gs://lldb_test_traces
export gsbinaries=gs://lldb_binaries
export llvmDir=$rootDir/llvm
export lldbDir=$llvmDir/tools/lldb
export lldDir=$llvmDir/tools/lld
export clangDir=$llvmDir/tools/clang
export cteDir=$llvmDir/tools/clang/tools/extra
export lockDir=/var/tmp/lldbbuild.exclusivelock
export TMPDIR=$rootDir/tmp/
mkdir -p $TMPDIR
