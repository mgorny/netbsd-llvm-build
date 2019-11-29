#!/usr/bin/env bash

# Do not generate any output from this file. It is sourced from files (getRevision.sh) that need
# a clean output stream.

set -e
ulimit -c unlimited
export originalDir=$(pwd)
export rootDir=$(pwd)/..
export buildDir=$rootDir/build
export wrapperDir=$rootDir/wrappers
export build2Dir=$rootDir/build-stage2
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
export projDir=$rootDir/llvm-project
export llvmDir=$projDir/llvm
export lockDir=/var/tmp/lldbbuild.exclusivelock
export TMPDIR=$rootDir/tmp/
mkdir -p $TMPDIR
