cmake_minimum_required(VERSION 3.20)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(DEFINED ENV{CPM_CACHE})
  set(CPM_SOURCE_CACHE "$ENV{CPM_CACHE}")
endif()

project(PlayGround LANGUAGES C CXX)

add_executable(${PROJECT_NAME} src/main.cpp)

include(cmake/CPM.cmake)

cpmaddpackage("gh:raysan5/raylib#4.2.0")

target_link_libraries(${PROJECT_NAME} PRIVATE raylib)
