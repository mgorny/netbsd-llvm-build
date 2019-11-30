#!/usr/bin/env bash
set -e
source setEnv.sh
source cleanUp.sh

markBuildIncomplete

buildType=Release

set -x

# stage 1
mkdir -p "$buildDir"
cd "$buildDir"

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
  -DLLVM_POLLY_BUILD=OFF \
  -DLLVM_TOOL_CLANG_TOOLS_EXTRA_BUILD=OFF \
  -DLLVM_TOOL_COMPILER_RT_BUILD=OFF \
  -DLLVM_TOOL_LLDB_BUILD=OFF \
  -DLLVM_TOOL_LIBCXXABI_BUILD=ON \
  -DLLVM_TOOL_LIBCXX_BUILD=ON \
  -DLLVM_TOOL_LIBUNWIND_BUILD=ON \
  -DLLVM_TOOL_OPENMP_BUILD=OFF \
  -DLLVM_TOOL_POLLY_BUILD=OFF \
  -DLLVM_TARGETS_TO_BUILD=host

#  -DLIBCXX_CXX_ABI=default \
#  -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
#  -DOPENMP_TEST_FLAGS="-cxx-isystem${PWD}/include/c++/v1" \

# reduce job count to make lldb tests more stable
sed -i -e '/COMMAND.*lit.*lldb\/lit$/s:-vv:-j1 -vv:' build.ninja

ninja \
	$(ninja -C "${buildDir}" -t targets all | cut -d: -f1 | grep '^[^-]*TableGen$')
ninja \
	$(ninja -C "${buildDir}" -t targets all | cut -d: -f1 | grep '\.a$')
ninja -j 4

# create cross-stage wrappers
mkdir -p "${wrapperDir}"
cat > "${wrapperDir}"/clang <<-EOF
	#!/bin/sh
	exec "${buildDir}"/bin/clang \
		-cxx-isystem${buildDir}/include/c++/v1 \
		-L${buildDir}/lib \
		-Wl,-rpath,${buildDir}/lib \
		-Wno-unused-command-line-argument \
		"\${@}"
EOF
cat > "${wrapperDir}"/clang++ <<-EOF
	#!/bin/sh
	exec "${buildDir}"/bin/clang++ \
		-cxx-isystem${buildDir}/include/c++/v1 \
		-L${buildDir}/lib \
		-Wl,-rpath,${buildDir}/lib \
		-Wno-unused-command-line-argument \
		"\${@}"
EOF
chmod +x "${wrapperDir}"/*

# stage 2
mkdir -p "$build2Dir"
cd "$build2Dir"
export PATH=${wrapperDir}:${buildDir}/bin:${PATH}
cmake -GNinja -DCMAKE_BUILD_TYPE="$buildType" "$llvmDir" \
  -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_BUILD_RPATH="${PWD}/lib;/usr/pkg/lib" \
  -DCMAKE_INSTALL_RPATH=/usr/pkg/lib \
  -DLLVM_LIT_ARGS="-vv;--shuffle"

markBuildComplete
