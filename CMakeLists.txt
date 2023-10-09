cmake_minimum_required(VERSION 3.12)

project(assign1
        VERSION 0.0.1
        DESCRIPTION ""
        LANGUAGES CXX)

message(STATUS "Compiler being used: ${CMAKE_CPP_COMPILER}")

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(main_SOURCES
    ${CMAKE_SOURCE_DIR}/main.cpp
    ${CMAKE_SOURCE_DIR}/display.cpp
)

set(main_HEADERS
    ${CMAKE_SOURCE_DIR}/display.hpp
)

add_executable(main ${main_SOURCES} ${main_HEADERS})

# Extract the compiler name without the path
message("C++ Compiler: ${CMAKE_CXX_COMPILER}")
get_filename_component(COMPILER_NAME "${CMAKE_CXX_COMPILER}" NAME_WE)
message("COMPILER_NAME: ${COMPILER_NAME}")

function(split_string_into_list _input_string _output_list)
    string(REGEX REPLACE "[ ]+" ";" _split_list "${_input_string}")
    set(${_output_list} ${_split_list} PARENT_SCOPE)
endfunction()

# Import warning_flags.txt
file(STRINGS "${CMAKE_SOURCE_DIR}/flags/${COMPILER_NAME}/warning_flags.txt" WARNING_FLAGS_STRING)
split_string_into_list("${WARNING_FLAGS_STRING}" WARNING_FLAGS_LIST)

# Import analyzer_flags.txt
file(STRINGS "${CMAKE_SOURCE_DIR}/flags/${COMPILER_NAME}/analyzer_flags.txt" ANALYZER_FLAGS_STRING)
split_string_into_list("${ANALYZER_FLAGS_STRING}" ANALYZER_FLAGS_LIST)

# Import debug_flags.txt
file(STRINGS "${CMAKE_SOURCE_DIR}/flags/${COMPILER_NAME}/debug_flags.txt" DEBUG_FLAGS_STRING)
split_string_into_list("${DEBUG_FLAGS_STRING}" DEBUG_FLAGS_LIST)

# Import sanitizer_flags.txt
file(STRINGS "${CMAKE_SOURCE_DIR}/flags/${COMPILER_NAME}/sanitizer_flags.txt" SANITIZER_FLAGS_STRING)
split_string_into_list("${SANITIZER_FLAGS_STRING}" SANITIZER_FLAGS_LIST)

# Common compiler flags
set(STANDARD_FLAGS
    -Werror
)

find_program(CLANG_FORMAT NAMES "clang-format" REQUIRED)
find_program(CLANG_TIDY NAMES "clang-tidy" REQUIRED)
find_program(CPPCHECK NAMES "cppcheck" REQUIRED)

# Format source files using clang-format
add_custom_target(format
    COMMAND ${CLANG_FORMAT} --style=file -i  ${main_SOURCES}  ${main_HEADERS}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Running clang-format"
)

add_dependencies(main format)

# Lint source files using clang-tidy
add_custom_command(
    TARGET main POST_BUILD
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMAND ${CLANG_TIDY}  ${main_SOURCES}  ${main_HEADERS} -quiet --warnings-as-errors='*' -checks=*,-llvmlibc-restrict-system-libc-headers,-altera-struct-pack-align,-readability-identifier-length,-altera-unroll-loops,-cppcoreguidelines-init-variables,-cert-err33-c,-modernize-macro-to-enum,-bugprone-easily-swappable-parameters,-clang-analyzer-security.insecureAPI.DeprecatedOrUnsafeBufferHandling,-altera-id-dependent-backward-branch,-concurrency-mt-unsafe,-misc-unused-parameters,-hicpp-signed-bitwise,-google-readability-todo,-cert-msc30-c,-cert-msc50-cpp,-readability-function-cognitive-complexity,-clang-analyzer-security.insecureAPI.strcpy,-cert-env33-c,-android-cloexec-accept,-clang-analyzer-security.insecureAPI.rand,-misc-include-cleaner,-llvmlibc-callee-namespace,-llvmlibc-implementation-in-namespace,-fuchsia-trailing-return,-modernize-use-trailing-return-type,-fuchsia-overloaded-operator,-fuchsia-default-arguments-calls,-cert-dcl21-cpp,-llvm-header-guard -- ${CMAKE_C_FLAGS} ${STANDARD_FLAGS} -I${CMAKE_SOURCE_DIR}/include -I/usr/local/include
    COMMENT "Running clang-tidy"
)

# Check if CMAKE_CPP_COMPILER starts with "clang"
if (CMAKE_CXX_COMPILER MATCHES ".*/clang.*")
    # Add a custom target for clang --analyze
    add_custom_command(
        TARGET main POST_BUILD
        COMMAND ${CMAKE_CXX_COMPILER} --analyzer-output text --analyze -Xclang -analyzer-checker=core --analyze -Xclang -analyzer-checker=deadcode -Xclang -analyzer-checker=security -Xclang -analyzer-disable-checker=security.insecureAPI.DeprecatedOrUnsafeBufferHandling -Xclang -analyzer-checker=unix -Xclang -analyzer-checker=unix ${CMAKE_C_FLAGS} ${STANDARD_FLAGS}  ${main_SOURCES}  ${main_HEADERS}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        COMMENT "Running clang --analyze"
    )
endif()

# Add a custom target for cppcheck
add_custom_command(
    TARGET main POST_BUILD
    COMMAND ${CPPCHECK} --error-exitcode=1 --force --quiet --library=posix --enable=all --suppress=missingIncludeSystem --suppress=unusedFunction --suppress=unmatchedSuppression  ${main_SOURCES}  ${main_HEADERS}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Running cppcheck"
)

# Set compiler flags for the target main
target_compile_options(main PRIVATE
    ${STANDARD_FLAGS}
    ${WARNING_FLAGS_LIST}
    ${ANALYZER_FLAGS_LIST}
    ${DEBUG_FLAGS_LIST}
    ${SANITIZER_FLAGS_LIST}
)

target_link_libraries(main PRIVATE ${SANITIZER_FLAGS_STRING})

