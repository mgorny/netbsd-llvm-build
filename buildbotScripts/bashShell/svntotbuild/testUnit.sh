#!/usr/bin/env bash
set -e
source setEnv.sh

tests=(
	check-lit
#	check-llvm    -- panics talia
	check-clang
#	check-clangd  -- huge breakage; TODO
	check-clang-tools
	check-polly
	check-lld
	check-lldb
	check-unwind
	check-openmp
	check-libcxxabi
	check-libcxx

	# compiler-rt
	check-builtins
#	check-interception -- can't find tests?!
#	check-lsan   -- needs patching for asan
#	check-ubsan  -- needs patching for asan/tsan
	check-cfi
	check-sanitizer
#	check-fuzzer -- aslr
	check-asan{,-dynamic}
	check-msan # also some aslr cases
	check-tsan
	check-safestack
	check-ubsan-minimal
	check-profile
#	check-xray -- mprotect
)

set -x
export FILECHECK_DUMP_INPUT_ON_FAILURE=1
ninja -v -k 9999 -C "$build2Dir" "${tests[@]}"
