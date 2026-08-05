cmake_minimum_required(VERSION 3.14)
project(p101_tests CXX)
enable_testing()
set_source_files_properties(unity/unity.c PROPERTIES LANGUAGE CXX)
add_library(unity STATIC unity/unity.c)
target_include_directories(unity PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/unity")
target_compile_options(unity PRIVATE -w)
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

# Apple Clang otherwise records its dynamic ASan runtime after the p101 shared
# libraries, which makes ASan abort before main with "loaded too late".
set(P101_ASAN_RUNTIME "")
if (APPLE AND CMAKE_CXX_COMPILER_ID MATCHES "Clang" AND
    CMAKE_CXX_FLAGS MATCHES "(^|[ ;])-fsanitize=address($|[ ;])")
    execute_process(
            COMMAND "${CMAKE_CXX_COMPILER}" --print-resource-dir
            OUTPUT_VARIABLE P101_CLANG_RESOURCE_DIR
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_QUIET)
    set(P101_ASAN_RUNTIME
        "${P101_CLANG_RESOURCE_DIR}/lib/darwin/libclang_rt.asan_osx_dynamic.dylib")
    if (NOT EXISTS "${P101_ASAN_RUNTIME}")
        message(FATAL_ERROR
                "AddressSanitizer runtime not found for ${CMAKE_CXX_COMPILER}: "
                "${P101_ASAN_RUNTIME}")
    endif ()
endif ()

option(P101_TEST_COVERAGE "Instrument the code under test" OFF)
set(_COV "")
if (P101_TEST_COVERAGE)
    set(_COV --coverage)
endif ()
set(P101_CODE_UNDER_TEST "${CMAKE_CURRENT_SOURCE_DIR}/../src/display.cpp")
function(p101_add_test name)
    add_executable(${name} ${ARGN} ${P101_CODE_UNDER_TEST})
    target_include_directories(${name} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/../include")
    target_include_directories(${name} PRIVATE ${P101_PUBLIC_INCLUDE_DIRS_LIST})
    target_link_directories(${name} PRIVATE ${P101_PUBLIC_LINK_DIRS_LIST})
    if (P101_ASAN_RUNTIME)
        target_link_libraries(${name} PRIVATE "${P101_ASAN_RUNTIME}")
    endif ()
    target_link_libraries(${name} PRIVATE unity p101_error p101_env p101_c p101_io)
    # Retain the admitted directories for transitive p101 dylib dependencies in
    # a standalone copy, including libraries found in an implicit linker path.
    set_target_properties(${name} PROPERTIES BUILD_RPATH "${P101_PUBLIC_LINK_DIRS_LIST}")
    target_compile_options(${name} PRIVATE ${_COV})
    target_link_options(${name} PRIVATE ${_COV})
    add_test(NAME ${name} COMMAND ${name})
endfunction()
p101_add_test(test_display test_display.cpp)
