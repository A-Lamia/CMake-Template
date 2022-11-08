cmake_minimum_required(VERSION 3.20)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(DEFINED ENV{CPM_CACHE})
  set(CPM_SOURCE_CACHE "$ENV{CPM_CACHE}")
endif()

if(DEFINED ENV{LLVM_ROOT})
  set(CMAKE_C_COMPILER "$ENV{LLVM_ROOT}/clang.exe")
  set(CMAKE_CXX_COMPILER "$ENV{LLVM_ROOT}/clang.exe")
  set(CMAKE_LINKER "$ENV{LLVM_ROOT}/lld-link.exe")
  set(CMAKE_C_COMPILER_ID Clang)
  set(CMAKE_CXX_COMPILER_ID Clang)
endif()

project(PlayGround LANGUAGES C CXX)

add_executable(${PROJECT_NAME} src/main.cpp)

include(cmake/CPM.cmake)

cpmaddpackage("gh:raysan5/raylib#4.2.0")

target_link_libraries(${PROJECT_NAME} PRIVATE raylib)
