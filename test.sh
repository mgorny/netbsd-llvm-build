#!/bin/bash

LLDB_UTILS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
INSTALL=$LLDB_UTILS/../../out/lldb/install/host

export LD_LIBRARY_PATH=$INSTALL/lib
export PYTHONHOME=$INSTALL

"$LLDB_UTILS/../../prebuilts/python/linux-x86/bin/python" \
	"$LLDB_UTILS/../lldb/test/dotest.py" \
	--executable "$INSTALL/bin/lldb"
