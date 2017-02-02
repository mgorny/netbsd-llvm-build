set(OS linux)

include(${CMAKE_CURRENT_LIST_DIR}/host.cmake)

# Configure LLVM
set(LLVM_USE_LINKER gold CACHE STRING "bfd, gold")
set(LLVM_TARGETS_TO_BUILD "X86;ARM;AArch64;Mips" CACHE STRING "X86, ARM, AArch64, Mips")
set(LLVM_ENABLE_EH ON CACHE BOOL "Enable exception handling")
set(LLVM_ENABLE_RTTI ON CACHE BOOL "Enable run-time type information")

set(PYTHON_EXECUTABLE "${PREBUILTS}/python/linux-x86/bin/python"
  CACHE STRING "Python executable")
set(PYTHON_LIBRARY "${PREBUILTS}/python/linux-x86/lib/libpython2.7.so"
  CACHE STRING "Python library")
set(PYTHON_INCLUDE_DIR "${PREBUILTS}/python/linux-x86/include/python2.7"
  CACHE STRING "Python include directory")
