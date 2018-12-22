#!/usr/bin/env bash
set -e
source setEnv.sh

set -x
ninja -k 9999 -C "$buildDir" check-lit check-llvm check-clang \
	check-clang-tools check-polly check-unwind \
	check-libcxxabi check-libcxx # check-lld test-suite check-openmp

# check-openmp and test-suite trigger lib(std)c++
