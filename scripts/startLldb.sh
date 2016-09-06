#!/bin/bash
# This is a VERY simple script to automate starting LLDB on an Android device.
# If it doesn't work for you, here are some things to look for:
#
# If you can't copy the lldb-server to the device, check the LLDB_SERVER_ARCH variable. Some
# architectures have the server in a directory with a slightly different name. See the armabi-v7a
# correction below.
#
# If you can't set breakpoints, it's not looking in the correct spot for the symbols, check the
# SYMBOL_ARCH variable. See the x86_64 correction below.
set -e

if [ "$1" != "" ]; then
  source $1
fi

shell()
{
  adb -s "$DEVICE" shell "$@"
}

push()
{
  adb -s "$DEVICE" push "$@"
}

show_usage()
{
echo "Usage: startLldb.sh <config_file>
The config file should contain the following Bash variable declarations:
  PKG: The package name in the format: tld.domain.your_app
  CLASS: The class of the starting activity in that package
  LLDB_DIR: The location where AS installed lldb

These values are optional:
  DEVICE: The Android device/emulator to use
  COMMANDS: Any commands to run in the lldb client after connecting, one per
  line

If DEVICE is not specified, and there is only one connected device, it will
use that device (similar to adb).

It is also possible to assign these variables via the shell, like standard
bash environment variables. In this case, no config file is necessary.
"
}

if [ "$DEVICE" = "" ]; then
  DEVICE_COUNT=`adb devices | grep 'device$' | wc -l`
  if [ $DEVICE_COUNT -eq 1 ]; then
    DEVICE=`adb devices | grep 'device$' | awk -F"\t+" '{print $1}'`
    echo "Using device: $DEVICE"
  fi
fi

if [[ -z "$PKG" || -z "$CLASS" || -z "$BUILD" || -z "$DEVICE" || -z "$LLDB_DIR" ]]; then
  show_usage
  exit 0
fi

APK="$BUILD/outputs/apk/app-all-debug.apk"
NOW=`date +%s`
SOCK="platform-${NOW}.sock"
ARCH=$(shell "getprop ro.product.cpu.abi" | tr -d '\r')

LLDB_SERVER_ARCH=$ARCH
if [ "$ARCH" = "armeabi-v7a" ]; then
  LLDB_SERVER_ARCH="armeabi"
fi

SYMBOL_ARCH=$ARCH
if [ "$ARCH" = "x86_64" ]; then
  SYMBOL_ARCH="x86"
fi

SYMBOL_PATH="$BUILD/intermediates/binaries/debug/all/obj/$SYMBOL_ARCH"
START_FILE=/tmp/lldb_commands.$NOW

R_TMP=/data/local/tmp
LLDB=/data/data/$PKG/lldb
LLDB_BIN=$LLDB/bin
LLDB_SERVER=$LLDB_BIN/lldb-server
START_SERVER=$LLDB_BIN/start_lldb_server.sh

push $LLDB_DIR/$LLDB_SERVER_ARCH/lldb-server $R_TMP
push $LLDB_DIR/start_lldb_server.sh $R_TMP
push $APK $R_TMP/$PKG
shell "pm install -r $R_TMP/$PKG"

shell "am start -n $PKG/${PKG}.$CLASS -a android.intent.action.MAIN -c android.intent.category.LAUNCHER"
shell "run-as $PKG mkdir -p $LLDB_BIN"
shell "rm -f $LLDB_SERVER"
shell "cat $R_TMP/lldb-server | run-as $PKG sh -c \"cat > $LLDB_SERVER && chmod 700 $LLDB_SERVER\""
shell "cat $R_TMP/start_lldb_server.sh | run-as $PKG sh -c \"cat > $START_SERVER && chmod 700 $LLDB_BIN/start_lldb_server.sh\""

PID=$(shell "ps" | grep "$PKG\s*$" | awk -F' +' '{print $2}')

echo "platform select remote-android
platform connect unix-abstract-connect://[$DEVICE]$LLDB/tmp/$SOCK
settings set auto-confirm true
settings set plugin.symbol-file.dwarf.comp-dir-symlink-paths /proc/self/cwd
settings set plugin.jit-loader.gdb.enable-jit-breakpoint true
settings set target.exec-search-paths $SYMBOL_PATH
command alias fv frame variable
process attach -p $PID
$COMMANDS" > $START_FILE

echo -n "Starting lldb server in the background"
shell "run-as $PKG $START_SERVER $LLDB unix-abstract $LLDB/tmp $SOCK \"lldb process:gdb-remote packets\""&
for i in {1..5}; do
  echo -n ' .'
  sleep 1
done
echo " done."

declare -a PIDS=( `pgrep -P $!` "$!" )

lldb -s $START_FILE

rm $START_FILE
# Need to kill the forked bash child process as well as the adb grandchild process.
kill "${PIDS[@]}"
