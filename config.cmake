set(PROJECT_NAME "template-cxx")
set(PROJECT_VERSION "1.0.0")
set(PROJECT_DESCRIPTION "Template C++ Project")
set(PROJECT_LANGUAGE "CXX")
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Common compiler flags
set(STANDARD_FLAGS
        -D_POSIX_C_SOURCE=200809L
        -D_XOPEN_SOURCE=700
        -Werror
)

set(DARWIN_STANDARD_FLAGS
        -D_DARWIN_C_SOURCE
)

set(LINUX_STANDARD_FLAGS
)

set(BSD_STANDARD_FLAGS
)

set(P101_TIDY_EXTRA_CHECKS
        # C++ projects intentionally use p101's printf-family wrappers. Those
        # wrappers retain compiler format checking, but clang-tidy's vararg
        # rules cannot distinguish them from unsafe ad-hoc vararg APIs.
        -cppcoreguidelines-pro-type-vararg
        -hicpp-vararg
)

# Define targets
set(EXECUTABLE_TARGETS main)
set(LIBRARY_TARGETS "")

set(main_SOURCES
        src/main.cpp
        src/display.cpp
)

set(main_HEADERS
        include/display.hpp
)

set(main_LINK_LIBRARIES
        p101_error
        p101_env
        p101_c
)

# The display test captures stdout through p101_io. Keep that test-only
# dependency out of the installed program's production dependency closure.
set(P101_TEST_LINK_LIBRARIES
        p101_io
)
