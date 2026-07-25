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

add_executable(fuzz fuzz_display.cpp "${CMAKE_CURRENT_SOURCE_DIR}/../src/display.cpp")
target_include_directories(fuzz PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/../include")
target_compile_options(fuzz PRIVATE ${_FUZZ_FLAGS})
target_link_options(fuzz PRIVATE ${_FUZZ_FLAGS})
