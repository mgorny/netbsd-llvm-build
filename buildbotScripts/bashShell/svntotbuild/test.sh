#!/usr/bin/env bash
set -e
source setEnv.sh

function appendCommonArgs {
  dotest_args+=(--executable "$buildDir/bin/lldb")
  dotest_args+=(--filecheck "$buildDir/bin/FileCheck")
  for c in "gdb-remote packets" "lldb all"; do
    dotest_args+=(--channel "$c")
  done
  for c in "${categories[@]}"; do
    case "$c" in
      -*)
        dotest_args+=(--skip-category "${c#-}")
        ;;
      +*)
        dotest_args+=(--category "${c#+}")
        ;;
    esac
  done
}

if [[ $1 == local* ]];
then
  source localTest.sh $1
else
  source androidTest.sh $1
fi
