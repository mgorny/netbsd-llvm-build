set(OS windows)

include(${CMAKE_CURRENT_LIST_DIR}/host.cmake)

set(LLDB_RELOCATABLE_PYTHON ON CACHE BOOL "Relocatable python")
set(PYTHON_HOME "${PREBUILTS}/python/windows-x86/x64" CACHE PATH "Python home")
