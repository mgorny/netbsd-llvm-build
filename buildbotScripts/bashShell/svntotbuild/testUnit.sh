#!/usr/bin/env bash
set -e
source setEnv.sh

set -x
export FILECHECK_DUMP_INPUT_ON_FAILURE=1
ninja -k 9999 -C "$buildDir" check-lit check-clang \
	check-clang-tools check-polly check-lld check-lldb
#	check-unwind check-openmp check-libcxxabi check-libcxx
# check-llvm \
	# test-suite
