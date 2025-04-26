set(PROJECT_NAME "template-cxx")
set(PROJECT_VERSION "1.0.0")
set(PROJECT_DESCRIPTION "Template C++ Project")
set(PROJECT_LANGUAGE "CXX")
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

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

set(main_LINK_LIBRARIES "")

