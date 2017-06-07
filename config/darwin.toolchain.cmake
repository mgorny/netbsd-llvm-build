include(${CMAKE_CURRENT_LIST_DIR}/paths.cmake)

set(CMAKE_OSX_DEPLOYMENT_TARGET 10.9 CACHE STRING "Minimum OSX version")
set(CMAKE_C_COMPILER "${PREBUILTS}/clang/host/darwin-x86/clang-4053586/bin/clang")
set(CMAKE_CXX_COMPILER "${PREBUILTS}/clang/host/darwin-x86/clang-4053586/bin/clang++")

foreach(SDK 10.12 10.11 10.10)
  execute_process(COMMAND xcrun --sdk macosx${SDK} --show-sdk-path
    RESULT_VARIABLE XCRUN_RESULT
    OUTPUT_VARIABLE XCRUN_STDOUT
    ERROR_VARIABLE XCRUN_STDERR
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  message(STATUS
    "xcrun looking for sdk ${SDK}. Stdout:\n${XCRUN_STDOUT}\nstderr:\n${XCRUN_STDERR}")
  if(${XCRUN_RESULT} EQUAL 0)
    break()
  endif()
endforeach()
if(NOT(${XCRUN_RESULT} EQUAL 0))
  message(FATAL_ERROR "Unable to find a suitable sdk")
endif()

set(CMAKE_SYSROOT ${XCRUN_STDOUT})

execute_process(COMMAND xcode-select --print-path
  RESULT_VARIABLE XCODE_SELECT_RESULT
  OUTPUT_VARIABLE XCODE_SELECT_STDOUT
  ERROR_VARIABLE XCODE_SELECT_STDERR
  OUTPUT_STRIP_TRAILING_WHITESPACE)
message(STATUS
  "xcode-select --print-path. Stdout:\n${XCODE_SELECT_STDOUT}\nstderr:\n${XCODE_SELECT_STDERR}")
if(NOT(${XCODE_SELECT_RESULT} EQUAL 0))
  message(FATAL_ERROR "Unable to find the developer directory")
endif()

set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES
    "${XCODE_SELECT_STDOUT}/Toolchains/XcodeDefault.xctoolchain/usr/include/c++/v1")
