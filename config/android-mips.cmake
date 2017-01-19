set(LLVM_TARGET_ARCH Mips)
set(LLVM_HOST_TRIPLE_ARCH mipsel)
set(LLVM_USE_LINKER bfd)
set(ANDROID_ABI mips)
set(ANDROID_PLATFORM android-9)

include(${CMAKE_CURRENT_LIST_DIR}/android.cmake)
