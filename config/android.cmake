# Configure cmake
set(CMAKE_GENERATOR Ninja CACHE STRING "CMake generator")
set(CMAKE_BUILD_TYPE MinSizeRel CACHE STRING "Release, MinSizeRel, RelWithDebInfo, Debug")
set(CMAKE_INSTALL_PREFIX "" CACHE STRING "Installation prefix")

# Configure LLVM
set(LLVM_TARGET_ARCH ${LLVM_TARGET_ARCH} CACHE STRING "X86, ARM, Aarch64, Mips")
set(LLVM_HOST_TRIPLE ${LLVM_HOST_TRIPLE_ARCH}-unknown-linux-android
  CACHE STRING "{i386,x86_64,armeabi,aarch64,mips,mips64}-unknown-linux-android")
set(LLVM_BUILD_STATIC FALSE CACHE BOOL "Statically link executables")
set(LLVM_USE_LINKER ${LLVM_USE_LINKER} CACHE STRING "bfd, gold")
set(LLVM_ENABLE_PIC TRUE CACHE BOOL "Enable position independent code")
set(LLVM_TARGETS_TO_BUILD ${LLVM_TARGET_ARCH} CACHE STRING "X86, ARM, AArch64, Mips")

set(CROSS_TOOLCHAIN_FLAGS_NATIVE
  "-DCMAKE_C_COMPILER=cc;-DCMAKE_CXX_COMPILER=c++;-DCMAKE_ASM_COMPILER=cc"
  CACHE STRING "Compilers to build tblgen targets with")

# Configure the toolchain file
set(ANDROID_ABI ${ANDROID_ABI}
  CACHE STRING "armeabi, armeabi-v7a, arm64-v8a, x86, x86_64, mips, mips64")
set(ANDROID_PLATFORM android-16 CACHE STRING "Android platform")
set(ANDROID_ALLOW_UNDEFINED_SYMBOLS ON
  CACHE BOOL "Allow undefined symbols when linking shared libraries")
set(ANDROID_PIE TRUE CACHE BOOL "Enable position independent executables")
set(ANDROID_STL "c++_static" CACHE STRING "Use LLVM libc++")

# Set the toolchain file
if ("$ENV{ANDROID_NDK_HOME}" STREQUAL "")
  message(WARNING "ANDROID_NDK_HOME environment variable not set. Don't forget "
                  "to set CMAKE_TOOLCHAIN_FILE manually.")
else()
  message(STATUS "Using Android NDK toolchain in $ENV{ANDROID_NDK_HOME}")
  set(CMAKE_TOOLCHAIN_FILE
    "$ENV{ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake"
    CACHE FILEPATH "Android toolchain file")
endif()

