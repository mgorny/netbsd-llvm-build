#!/bin/bash -e
set -x
rm -rf *
git clone https://android.googlesource.com/platform/external/lldb-utils -b lldb-master-dev
cp lldb-utils/buildbotScripts/bashShell/svntotbuild/* .
cp ../test_cfg.json test_cfg.json
