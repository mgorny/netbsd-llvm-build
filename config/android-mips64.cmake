set(LLVM_TARGET_ARCH Mips)
set(LLVM_HOST_TRIPLE_ARCH mips64el)
set(LLVM_USE_LINKER bfd)
set(ANDROID_ABI mips64)

include(${CMAKE_CURRENT_LIST_DIR}/android.cmake)
