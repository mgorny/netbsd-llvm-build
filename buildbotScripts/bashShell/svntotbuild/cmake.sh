#!/usr/bin/env bash
set -e
set -x

source setEnv.sh
source cleanUp.sh

markBuildIncomplete

buildType=Release
mkdir -p "$buildDir"
cd "$buildDir"
host=$(uname)
if [[ "$host" == NetBSD ]]; then
  # TODO: /usr/pkg/lib rpath needs to be appended after builddir
  # NOTICE: change -DLIBCXX_CXX_ABI to 'libcxxabi' when upstream recommits
  # 'Do not cleverly link against libc++abi just because it happens to be there'
  cmake -GNinja -DCMAKE_BUILD_TYPE="$buildType" "$llvmDir" \
    -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_C_FLAGS_RELEASE='-O2' -DCMAKE_CXX_FLAGS_RELEASE='-O2' \
    -DCMAKE_BUILD_RPATH="${PWD}/lib;/usr/pkg/lib" \
    -DCMAKE_INSTALL_RPATH=/usr/pkg/lib \
    -DLIBCXX_CXX_ABI=default \
    -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
    -DLLVM_LIT_ARGS="-vv;--shuffle;--param;cxx_under_test=${PWD}/bin/clang++" \
    -DOPENMP_TEST_FLAGS="-cxx-isystem${PWD}/include/c++/v1"

  # reduce job count to make lldb tests more stable
  sed -i -e '/COMMAND.*lit.*lldb\/lit$/s:-vv:-j1 -vv:' build.ninja
elif [[ "$host" == Linux ]]; then
  cmake -GNinja -DCMAKE_BUILD_TYPE="$buildType" "$llvmDir" -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DLLVM_ENABLE_EH=YES -DLLVM_ENABLE_RTTI=YES "$@"
else
  cmake -GNinja -DCMAKE_BUILD_TYPE="$buildType" "$llvmDir" -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++
fi
