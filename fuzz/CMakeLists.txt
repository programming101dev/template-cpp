# Standalone libFuzzer tree (clang-only). ./fuzz.sh selects a fuzzer-capable
# clang++ and passes it as CMAKE_CXX_COMPILER. Separate from the strict build.
#
# EXAMPLE target: the template's display() is compiled in (instrumented) so the
# harness is coverage-guided. display() only prints, so this finds nothing by
# design — see fuzz_display.cpp and point it at your own input-parsing code.
cmake_minimum_required(VERSION 3.14)
project(p101_fuzz CXX)

if (NOT CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    message(FATAL_ERROR "Fuzzing needs clang++ with libFuzzer (-fsanitize=fuzzer); got '${CMAKE_CXX_COMPILER_ID}'. Use ./fuzz.sh, which picks a fuzzer-capable clang++.")
endif ()

set(_FUZZ_FLAGS -fsanitize=fuzzer,address,undefined -g -O1)
set(P101_PUBLIC_INCLUDE_DIRS "" CACHE STRING "Extra p101 include dirs")
set(P101_PUBLIC_LINK_DIRS "" CACHE STRING "Extra p101 link dirs")
separate_arguments(P101_PUBLIC_INCLUDE_DIRS_LIST NATIVE_COMMAND "${P101_PUBLIC_INCLUDE_DIRS}")
separate_arguments(P101_PUBLIC_LINK_DIRS_LIST NATIVE_COMMAND "${P101_PUBLIC_LINK_DIRS}")
list(APPEND P101_PUBLIC_INCLUDE_DIRS_LIST /usr/local/include)
list(APPEND P101_PUBLIC_LINK_DIRS_LIST /usr/local/lib /usr/local/lib64)
if (APPLE)
    list(APPEND P101_PUBLIC_INCLUDE_DIRS_LIST /opt/homebrew/include /opt/local/include)
    list(APPEND P101_PUBLIC_LINK_DIRS_LIST /opt/homebrew/lib /opt/local/lib)
endif ()

add_executable(fuzz fuzz_display.cpp "${CMAKE_CURRENT_SOURCE_DIR}/../src/display.cpp")
target_include_directories(fuzz PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/../include")
target_include_directories(fuzz PRIVATE ${P101_PUBLIC_INCLUDE_DIRS_LIST})
target_link_directories(fuzz PRIVATE ${P101_PUBLIC_LINK_DIRS_LIST})
target_link_libraries(fuzz PRIVATE p101_error p101_env p101_c)
target_compile_options(fuzz PRIVATE ${_FUZZ_FLAGS})
target_link_options(fuzz PRIVATE ${_FUZZ_FLAGS})
