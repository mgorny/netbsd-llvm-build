#!/bin/bash -e
source setEnv_ASBuild.sh
set -x
cd $rootDir
rm -f *.zip
export gs_asbin_linux=gs://android-build-lldb/builds/git_lldb-$1-linux-lldb_linux
export gs_asbin_darwin=gs://android-build-lldb/builds/git_lldb-$1-mac-lldb_darwin
rm -rf $lldbDir
rm -rf $buildDir
gsutil cp -r $gs_asbin_linux/$2/** .
unzip -o lldb-tests-$2 -d $lldbDir/
unzip -o lldb-android-$2 -d $buildDir/

if [ $(uname) == Darwin ]
then
  gsutil cp -r $gs_asbin_darwin/$2/** .
  unzip -o lldb-mac-$2 -d $buildDir/bin/
else
  unzip -o lldb-linux-$2 -d $buildDir/
fi

