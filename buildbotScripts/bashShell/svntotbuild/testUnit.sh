#!/usr/bin/env bash
set -e
source setEnv.sh
export PATH=${wrapperDir}:${buildDir}/bin:${PATH}

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
	check-lsan
	check-ubsan
	check-cfi
	check-sanitizer
#	check-fuzzer -- lots o' breakage
	check-asan{,-dynamic}
	check-msan
	check-tsan
	check-safestack
	check-ubsan-minimal
	check-profile
	check-xray
)

set -x
export FILECHECK_DUMP_INPUT_ON_FAILURE=1
ninja -v -k 9999 -C "$build2Dir" "${tests[@]}"
