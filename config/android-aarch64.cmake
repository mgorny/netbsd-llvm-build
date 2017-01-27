set(LLVM_TARGET_ARCH AArch64)
set(LLVM_HOST_TRIPLE_ARCH aarch64)
set(LLVM_USE_LINKER gold)
set(ANDROID_ABI arm64-v8a)

include(${CMAKE_CURRENT_LIST_DIR}/android.cmake)
