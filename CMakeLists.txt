cmake_minimum_required(VERSION 3.12.0)

set(TARGET_NAME wolfram-engine)
project(${TARGET_NAME})

set(SOURCE_DIR ${PROJECT_SOURCE_DIR}/src)
file(GLOB_RECURSE SOURCE_FILES LIST_DIRECTORIES false
    "${SOURCE_DIR}/*.cpp"
    "${SOURCE_DIR}/*.hpp"
)

add_executable(${TARGET_NAME} ${SOURCE_FILES})

add_subdirectory(external/glm)
add_subdirectory(external/nativefiledialog)
add_subdirectory(external/SDL2)
add_subdirectory(external/stb)
add_subdirectory(external/tinygltf)

target_compile_options(${TARGET_NAME} PRIVATE -Wall -Wextra -pedantic -Werror)

target_link_libraries(${TARGET_NAME}
    general sdl2
)