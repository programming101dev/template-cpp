cmake_minimum_required(VERSION 3.12)

project(main
        VERSION 0.0.1
        DESCRIPTION ""
        LANGUAGES CXX)

message(STATUS "Compiler being used: ${CMAKE_CXX_COMPILER}")

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

list(APPEND SOURCES ${CMAKE_SOURCE_DIR}/main.cpp)
list(APPEND SOURCES ${CMAKE_SOURCE_DIR}/display.cpp)
list(APPEND HEADERS ${CMAKE_SOURCE_DIR}/display.hpp)

set(main_SOURCES
    ${CMAKE_SOURCE_DIR}/main.cpp
    ${CMAKE_SOURCE_DIR}/display.cpp
)

set(main_HEADERS
    ${CMAKE_SOURCE_DIR}/display.hpp
)

add_executable(main ${main_SOURCES})

message("C++ Compiler: ${CMAKE_CXX_COMPILER}")
get_filename_component(COMPILER_NAME "${CMAKE_CXX_COMPILER}" NAME_WE)
message("COMPILER_NAME: ${COMPILER_NAME}")

function(split_string_into_list _input_string _output_list)
    string(REGEX REPLACE "[ ]+" ";" _split_list "${_input_string}")
    set(${_output_list} ${_split_list} PARENT_SCOPE)
endfunction()

file(STRINGS "${CMAKE_SOURCE_DIR}/flags/${COMPILER_NAME}/warning_flags.txt" WARNING_FLAGS_STRING)
split_string_into_list("${WARNING_FLAGS_STRING}" WARNING_FLAGS_LIST)

file(STRINGS "${CMAKE_SOURCE_DIR}/flags/${COMPILER_NAME}/analyzer_flags.txt" ANALYZER_FLAGS_STRING)
split_string_into_list("${ANALYZER_FLAGS_STRING}" ANALYZER_FLAGS_LIST)

file(STRINGS "${CMAKE_SOURCE_DIR}/flags/${COMPILER_NAME}/debug_flags.txt" DEBUG_FLAGS_STRING)
split_string_into_list("${DEBUG_FLAGS_STRING}" DEBUG_FLAGS_LIST)

file(STRINGS "${CMAKE_SOURCE_DIR}/flags/${COMPILER_NAME}/sanitizer_flags.txt" SANITIZER_FLAGS_STRING)
split_string_into_list("${SANITIZER_FLAGS_STRING}" SANITIZER_FLAGS_LIST)

set(STANDARD_FLAGS
    -Werror
)

# Set compiler flags for the target main
target_compile_options(main PRIVATE
    ${STANDARD_FLAGS}
    ${WARNING_FLAGS_LIST}
    ${ANALYZER_FLAGS_LIST}
    ${DEBUG_FLAGS_LIST}
    ${SANITIZER_FLAGS_LIST}
)
# Add target_link_libraries for main
target_link_libraries(main PRIVATE ${SANITIZER_FLAGS_STRING})

find_program(CLANG_FORMAT NAMES "clang-format" REQUIRED)
find_program(CLANG_TIDY NAMES "clang-tidy" REQUIRED)
find_program(CPPCHECK NAMES "cppcheck" REQUIRED)

add_custom_target(format
    COMMAND ${CLANG_FORMAT} --style=file -i ${SOURCES} ${HEADERS}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Running clang-format"
)

add_dependencies(main format)

add_custom_command(
    TARGET main POST_BUILD
    COMMAND ${CPPCHECK} --error-exitcode=1 --force --quiet --library=posix --enable=all --suppress=missingIncludeSystem --suppress=unusedFunction --suppress=unmatchedSuppression ${SOURCES} ${HEADERS}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Running clang-tidy"
)

if (CMAKE_CXX_COMPILER MATCHES ".*/clang.*")
    # Add a custom target for clang --analyze
    add_custom_command(
        TARGET main POST_BUILD
        COMMAND ${CMAKE_CXX_COMPILER} --analyzer-output text --analyze -Xclang -analyzer-checker=core --analyze -Xclang -analyzer-checker=deadcode -Xclang -analyzer-checker=security -Xclang -analyzer-disable-checker=security.insecureAPI.DeprecatedOrUnsafeBufferHandling -Xclang -analyzer-checker=unix -Xclang -analyzer-checker=unix ${CMAKE_C_FLAGS} ${STANDARD_FLAGS}  ${SOURCES} ${HEADERS}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        COMMENT "Running clang --analyze"
    )
endif ()

add_custom_command(
    TARGET main POST_BUILD
    COMMAND ${CPPCHECK} --error-exitcode=1 --force --quiet --library=posix --enable=all --suppress=missingIncludeSystem --suppress=unusedFunction --suppress=unmatchedSuppression ${SOURCES} ${HEADERS}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Running cppcheck"
)

