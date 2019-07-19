#!/usr/bin/env bash
set -e
source setEnv.sh

set -x
export FILECHECK_DUMP_INPUT_ON_FAILURE=1
ninja -k 9999 -C "$buildDir" check-lit check-llvm check-clang \
	check-clang-tools check-polly check-unwind check-openmp \
	check-libcxxabi check-libcxx check-lld check-lldb-lit
	# test-suite
