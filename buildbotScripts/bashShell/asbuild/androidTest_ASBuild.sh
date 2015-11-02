#!/bin/bash -e
config=(${1//,/ })
export deviceId=${config[0]}
export compiler=${config[1]}
export arch=${config[2]}
function clean {
  adb -s $deviceId shell ps | grep lldb-server | awk '{print $2}' | xargs adb -s $deviceId shell kill || true
  adb -s $deviceId shell rm -r $remoteDir || true
}
trap clean EXIT

ndkApiList=(21 19 18 17 16 15 14 13 12 9 8 5 4 3)
function getNdkApi {
  local e
  for e in "${ndkApiList[@]}"; do
    if [[ "$e" -le "$1" ]]
    then
      echo $e
      return
    fi
  done
}
function getAltDir {
  if [ $arch == i386 ]
  then
     echo x86
  elif [ $arch == arm ]
  then
     echo armeabi
  elif [ $arch == aarch64 ]
  then
     echo arm64-v8a
  else
     echo $arch
  fi
}
function getBinDir {
  if [ -d "$buildDir/$arch" ]; then
    echo $arch
  else
    echo $(getAltDir)
  fi
}
set -x
rm -rf $lldbDir
unzip -o $rootDir/lldb-tests-* -d $lldbDir/
cd $lldbDir
find test -exec touch {} +
cd $rootDir/scripts
adb -s $deviceId shell getprop ro.build.fingerprint
adb -s $deviceId shell ps | grep lldb-server | awk '{print $2}' | xargs adb -s $deviceId shell kill || true
adb -s $deviceId shell rm -r $remoteDir || true
adb -s $deviceId shell mkdir $remoteDir
adb -s $deviceId push $buildDir/$(getBinDir)/lldb-server $remoteDir/
adb forward --remove-all
screen -d -m adb -s $deviceId shell TMPDIR=$remoteDir/tmp $remoteDir/lldb-server platform --listen 127.0.0.1:$port --server

export LLDB_TEST_THREADS=8

lldbPath=$buildDir/bin/lldb
apilevel=$(adb -s $deviceId shell getprop ro.build.version.sdk)
apilevel=${apilevel//[[:space:]]/}

ndkapi=$(getNdkApi $apilevel)
unset PYTHONPATH
export PYTHONHOME=$buildDir
cmd="$lldbDir/test/dotest.py \
--executable $lldbPath \
-A $arch -C $toolchain/$arch-$ndkapi/bin/$compiler \
-s logs-$compiler-$arch -u CXXFLAGS -u CFLAGS \
--channel \"gdb-remote packets\" --channel \"lldb all\" \
--platform-name remote-android \
--platform-url adb://$deviceId:$port \
--platform-working-dir $remoteDir \
--env OS=Android \
--skip-category lldb-mi"

eval $cmd
