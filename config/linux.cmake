set(REPO_ROOT ${CMAKE_CURRENT_LIST_DIR}/../../..)
set(PREBUILTS ${REPO_ROOT}/prebuilts)

# Configure cmake
set(CMAKE_GENERATOR Ninja CACHE STRING "CMake generator")
set(CMAKE_MAKE_PROGRAM "${PREBUILTS}/ninja/linux-x86/ninja" CACHE STRING "Ninja program")
set(CMAKE_BUILD_TYPE Release CACHE STRING "Release, MinSizeRel, RelWithDebInfo, Debug")
set(CMAKE_INSTALL_PREFIX "" CACHE STRING "Installation prefix")

# Configure LLVM
set(LLVM_USE_LINKER gold CACHE STRING "bfd, gold")
set(LLVM_TARGETS_TO_BUILD "X86;ARM;AArch64;Mips" CACHE STRING "X86, ARM, AArch64, Mips")
set(LLVM_ENABLE_EH ON CACHE BOOL "Enable exception handling")
set(LLVM_ENABLE_RTTI ON CACHE BOOL "Enable run-time type information")
set(LLVM_EXTERNAL_CLANG_SOURCE_DIR "${REPO_ROOT}/external/clang"
  CACHE STRING "Clang source path")
set(LLVM_EXTERNAL_LLDB_SOURCE_DIR "${REPO_ROOT}/external/lldb"
  CACHE STRING "LLDB source path")

set(LLDB_DISABLE_CURSES ON CACHE BOOL "Disable curses support")

set(PYTHON_EXECUTABLE "${PREBUILTS}/python/linux-x86/bin/python"
  CACHE STRING "Python executable")
set(PYTHON_LIBRARY "${PREBUILTS}/python/linux-x86/lib/libpython2.7.so"
  CACHE STRING "Python library")
set(PYTHON_INCLUDE_DIR "${PREBUILTS}/python/linux-x86/include/python2.7"
  CACHE STRING "Python include directory")

set(SWIG_EXECUTABLE "${PREBUILTS}/swig/linux-x86/bin/swig"
  CACHE STRING "Swig executable")

set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/linux.toolchain.cmake"
  CACHE STRING "Toolchain file")
