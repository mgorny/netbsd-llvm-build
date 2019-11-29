#!/usr/bin/env bash
set -e
set -x

source setEnv.sh
source cleanUp.sh

markBuildIncomplete

buildType=Release
mkdir -p "$buildDir"
cd "$buildDir"

# stage 1

# TODO: /usr/pkg/lib rpath needs to be appended after builddir
# NOTICE: change -DLIBCXX_CXX_ABI to 'libcxxabi' when upstream recommits
# 'Do not cleverly link against libc++abi just because it happens to be there'
cmake -GNinja -DCMAKE_BUILD_TYPE="$buildType" "$llvmDir" \
  -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ \
  -DCMAKE_C_FLAGS_RELEASE='-O2' -DCMAKE_CXX_FLAGS_RELEASE='-O2' \
  -DCMAKE_BUILD_RPATH="${PWD}/lib;/usr/pkg/lib" \
  -DCMAKE_INSTALL_RPATH=/usr/pkg/lib \
  -DLLVM_LIT_ARGS="-vv;--shuffle;--param;cxx_under_test=${PWD}/bin/clang++" \
  -DLLVM_CCACHE_BUILD=ON \
  -DLLVM_TOOL_COMPILER_RT_BUILD=OFF \
  -DLLVM_TOOL_LIBCXXABI_BUILD=OFF \
  -DLLVM_TOOL_LIBCXX_BUILD=OFF \
  -DLLVM_TOOL_LIBUNWIND_BUILD=OFF \
  -DLLVM_TOOL_OPENMP_BUILD=OFF

#  -DLIBCXX_CXX_ABI=default \
#  -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
#  -DOPENMP_TEST_FLAGS="-cxx-isystem${PWD}/include/c++/v1" \

# reduce job count to make lldb tests more stable
sed -i -e '/COMMAND.*lit.*lldb\/lit$/s:-vv:-j1 -vv:' build.ninja
