cmake_minimum_required(VERSION 3.12)

project(main
        VERSION 0.0.1
        DESCRIPTION ""
        LANGUAGES CXX)

message(STATUS "Compiler being used: ${CMAKE_CXX_COMPILER}")

set(CMAKE_CPP_STANDARD 20)
set(CMAKE_CPP_STANDARD_REQUIRED ON)
set(CMAKE_CPP_EXTENSIONS OFF)

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


message("C Compiler: ${CMAKE_CXX_COMPILER}")
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
    -D_POSIX_C_SOURCE=200809L
    -D_XOPEN_SOURCE=700
    -D_GNU_SOURCE
    -D_DARWIN_C_SOURCE
    -D__BSD_VISIBLE
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

if (NOT DEFINED CLANG_FORMAT_NAME)
    set(CLANG_FORMAT_NAME "clang-format")
endif()

if (NOT DEFINED CLANG_TIDY_NAME)
    set(CLANG_TIDY_NAME "clang-tidy")
endif()

if (NOT DEFINED CPPCHECK_NAME)
    set(CPPCHECK_NAME "cppcheck")
endif()

find_program(CLANG_FORMAT NAMES ${CLANG_FORMAT_NAME} REQUIRED)
find_program(CLANG_TIDY NAMES ${CLANG_TIDY_NAME} REQUIRED)
find_program(CPPCHECK NAMES ${CPPCHECK_NAME} REQUIRED)

add_custom_target(format
    COMMAND ${CLANG_FORMAT} --style=file -i ${SOURCES} ${HEADERS}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Running clang-format"
)

add_dependencies(main format)

add_custom_command(
    TARGET main POST_BUILD
    COMMAND ${CLANG_TIDY} ${SOURCES} ${HEADERS} -quiet --warnings-as-errors='*' -checks=*,-llvmlibc-restrict-system-libc-headers,-altera-struct-pack-align,-readability-identifier-length,-altera-unroll-loops,-cppcoreguidelines-init-variables,-cert-err33-c,-modernize-macro-to-enum,-bugprone-easily-swappable-parameters,-clang-analyzer-security.insecureAPI.DeprecatedOrUnsafeBufferHandling,-altera-id-dependent-backward-branch,-concurrency-mt-unsafe,-misc-unused-parameters,-hicpp-signed-bitwise,-google-readability-todo,-cert-msc30-c,-cert-msc50-cpp,-readability-function-cognitive-complexity,-clang-analyzer-security.insecureAPI.strcpy,-cert-env33-c,-android-cloexec-accept,-clang-analyzer-security.insecureAPI.rand,-misc-include-cleaner,-llvmlibc-implementation-in-namespace,-modernize-use-trailing-return-type,-fuchsia-default-arguments-calls,-llvmlibc-callee-namespace,-fuchsia-overloaded-operator,-cert-dcl21-cpp,-cppcoreguidelines-special-member-functions,-hicpp-special-member-functions,-llvm-header-guard,-fuchsia-trailing-return,-performance-avoid-endl -- ${STANDARD_FLAGS} -I/usr/local/include
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Running clang-tidy"
)

if (CMAKE_CXX_COMPILER MATCHES ".*/clang.*")
    # Add a custom target for clang --analyze
    add_custom_command(
        TARGET main POST_BUILD
        COMMAND ${CMAKE_CXX_COMPILER} --analyzer-output text --analyze -Xclang -analyzer-checker=core --analyze -Xclang -analyzer-checker=deadcode -Xclang -analyzer-checker=security -Xclang -analyzer-disable-checker=security.insecureAPI.DeprecatedOrUnsafeBufferHandling -Xclang -analyzer-checker=unix -Xclang -analyzer-checker=unix ${CMAKE_C_FLAGS} ${STANDARD_FLAGS} ${SOURCES} ${HEADERS}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        COMMENT "Running clang --analyze"
    )

    # Add a custom command to delete .gch files after the analysis
    add_custom_command(
        TARGET main POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E remove ${CMAKE_SOURCE_DIR}/*.gch
        COMMENT "Removing .gch files"
    )
endif ()

add_custom_command(
    TARGET main POST_BUILD
    COMMAND ${CPPCHECK} --error-exitcode=1 --force --quiet --inline-suppr --library=posix --enable=all --suppress=missingIncludeSystem --suppress=unusedFunction --suppress=unmatchedSuppression --suppress=checkersReport ${SOURCES} ${HEADERS}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Running cppcheck"
)

