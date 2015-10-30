#!/bin/bash -e
config=(${1//,/ })

compiler=${config[1]}
arch=${config[2]}

if [ $compiler == "totclang" ]
then
  compiler=$buildDir/bin/clang
fi

host=$(uname)
cmd="$lldbDir/packages/Python/lldbsuite/test/dotest.py \
--executable $buildDir/bin/lldb \
-A $arch -C $compiler \
-s logs-${config[1]}-$arch \
-u CXXFLAGS -u CFLAGS \
--channel \"gdb-remote packets\" \
--channel \"lldb all\""

echo $cmd
eval $cmd
