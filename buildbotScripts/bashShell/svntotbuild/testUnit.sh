#!/usr/bin/env bash
set -e
source setEnv.sh

set -x
nice -n 10 ninja -k 9999 -C "$buildDir" check-lit check-llvm check-clang \
	check-clang-tools check-lld check-polly check-unwind \
	check-libcxxabi check-openmp
