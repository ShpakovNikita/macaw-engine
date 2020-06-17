cmake_minimum_required(VERSION 3.12.0)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake")

set(TARGET_NAME wolfram-engine)
project(${TARGET_NAME})

set(SOURCE_DIR ${PROJECT_SOURCE_DIR}/src)
file(GLOB_RECURSE SOURCE_FILES LIST_DIRECTORIES false
    "${SOURCE_DIR}/*.cpp"
    "${SOURCE_DIR}/*.hpp"
)

include_directories(external/glm)
include_directories(external/nativefiledialog)
include_directories(external/stb)
include_directories(external/tinygltf)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(SDL2 REQUIRED)
include_directories(${SDL2_INCLUDE_DIRS})

add_executable(${TARGET_NAME} ${SOURCE_FILES})

target_link_libraries(${TARGET_NAME} ${SDL2_LIBRARIES})
target_compile_options(${TARGET_NAME} PRIVATE -Wall -Wextra -pedantic -Werror)