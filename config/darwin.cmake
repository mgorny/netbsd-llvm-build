set(OS darwin)

include(${CMAKE_CURRENT_LIST_DIR}/host.cmake)

set(LLDB_CODESIGN_IDENTITY "" CACHE STRING "Codesign identity")
