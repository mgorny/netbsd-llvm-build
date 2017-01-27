set(LLVM_TARGET_ARCH ARM)
set(LLVM_HOST_TRIPLE_ARCH armeabi)
set(LLVM_USE_LINKER gold)
set(ANDROID_ABI armeabi-v7a)

include(${CMAKE_CURRENT_LIST_DIR}/android.cmake)
