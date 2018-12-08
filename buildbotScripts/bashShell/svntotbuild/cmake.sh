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
  cmake -GNinja -DCMAKE_BUILD_TYPE="$buildType" "$llvmDir" \
    -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ \
    -DCMAKE_BUILD_RPATH="${PWD}/lib;/usr/pkg/lib" \
    -DCMAKE_INSTALL_RPATH=/usr/pkg/lib \
    -DLIBCXXABI_USE_LLVM_UNWINDER=ON
elif [[ "$host" == Linux ]]; then
  cmake -GNinja -DCMAKE_BUILD_TYPE="$buildType" "$llvmDir" -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DLLVM_ENABLE_EH=YES -DLLVM_ENABLE_RTTI=YES "$@"
else
  cmake -GNinja -DCMAKE_BUILD_TYPE="$buildType" "$llvmDir" -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++
fi
