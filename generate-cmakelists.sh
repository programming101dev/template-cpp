#!/usr/bin/env bash

# Output file for CMakeLists.txt
input_file="files.txt"
output_file="CMakeLists.txt"

# Function to generate CMakeLists-like content
generate_cmake_content() {
  local entity="$1"
  shift
  local sources=""
  local headers=""

  for file in "$@"; do
    if [[ $file == *".cpp" ]]; then
      sources="${sources}    \${CMAKE_SOURCE_DIR}/$file\n"
      echo "list(APPEND SOURCES \${CMAKE_SOURCE_DIR}/$file)" >> "$output_file"
    elif [[ $file == *".hpp" ]]; then
      headers="${headers}    \${CMAKE_SOURCE_DIR}/$file\n"
      echo "list(APPEND HEADERS \${CMAKE_SOURCE_DIR}/$file)" >> "$output_file"
    fi
  done

  echo "" >> "$output_file"
  echo "set(${entity}_SOURCES" >> "$output_file"
  echo -e "$sources)" >> "$output_file"
  echo "" >> "$output_file"
  echo "set(${entity}_HEADERS" >> "$output_file"
  echo -e "$headers)" >> "$output_file"
  echo "" >> "$output_file"
  echo "add_executable($entity \${${entity}_SOURCES})" >> "$output_file"
  echo "" >> "$output_file"
}

# Additional code
{
  # Read the first line of files.txt to determine the first target
  first_target=$(awk '{print $1; exit}' "$input_file")
  echo "cmake_minimum_required(VERSION 3.12)" > "$output_file"
  echo "" >> "$output_file"
  echo "project($first_target" >> "$output_file"
  echo "        VERSION 0.0.1" >> "$output_file"
  echo "        DESCRIPTION \"\"" >> "$output_file"
  echo "        LANGUAGES CXX)" >> "$output_file"
  echo "" >> "$output_file"
  echo "message(STATUS \"Compiler being used: \${CMAKE_CXX_COMPILER}\")" >> "$output_file"
  echo "" >> "$output_file"
  echo "set(CMAKE_CXX_STANDARD 20)" >> "$output_file"
  echo "set(CMAKE_CXX_STANDARD_REQUIRED ON)" >> "$output_file"
  echo "set(CMAKE_CXX_EXTENSIONS OFF)" >> "$output_file"
  echo "" >> "$output_file"

  # Read the file and process lines
  targets=()  # Array to store target names
  while IFS= read -r line; do
    arr=($line)
    if [ "${#arr[@]}" -ge 2 ]; then
      entity="${arr[0]}"
      files="${arr[@]:1}"
      targets+=("$entity")  # Add the target name to the array
      generate_cmake_content "$entity" $files
    fi
  done < "$input_file"

  # Extract the compiler name without the path
  echo "message(\"C++ Compiler: \${CMAKE_CXX_COMPILER}\")" >> "$output_file"
  echo "get_filename_component(COMPILER_NAME \"\${CMAKE_CXX_COMPILER}\" NAME_WE)" >> "$output_file"
  echo "message(\"COMPILER_NAME: \${COMPILER_NAME}\")" >> "$output_file"
  echo "" >> "$output_file"

  echo "function(split_string_into_list _input_string _output_list)" >> "$output_file"
  echo "    string(REGEX REPLACE \"[ ]+\" \";\" _split_list \"\${_input_string}\")" >> "$output_file"
  echo "    set(\${_output_list} \${_split_list} PARENT_SCOPE)" >> "$output_file"
  echo "endfunction()" >> "$output_file"
  echo "" >> "$output_file"

  # Import warning_flags.txt
  echo "file(STRINGS \"\${CMAKE_SOURCE_DIR}/flags/\${COMPILER_NAME}/warning_flags.txt\" WARNING_FLAGS_STRING)" >> "$output_file"
  echo "split_string_into_list(\"\${WARNING_FLAGS_STRING}\" WARNING_FLAGS_LIST)" >> "$output_file"
  echo "" >> "$output_file"

  # Import analyzer_flags.txt
  echo "file(STRINGS \"\${CMAKE_SOURCE_DIR}/flags/\${COMPILER_NAME}/analyzer_flags.txt\" ANALYZER_FLAGS_STRING)" >> "$output_file"
  echo "split_string_into_list(\"\${ANALYZER_FLAGS_STRING}\" ANALYZER_FLAGS_LIST)" >> "$output_file"
  echo "" >> "$output_file"

  # Import debug_flags.txt
  echo "file(STRINGS \"\${CMAKE_SOURCE_DIR}/flags/\${COMPILER_NAME}/debug_flags.txt\" DEBUG_FLAGS_STRING)" >> "$output_file"
  echo "split_string_into_list(\"\${DEBUG_FLAGS_STRING}\" DEBUG_FLAGS_LIST)" >> "$output_file"
  echo "" >> "$output_file"

  # Import sanitizer_flags.txt
  echo "file(STRINGS \"\${CMAKE_SOURCE_DIR}/flags/\${COMPILER_NAME}/sanitizer_flags.txt\" SANITIZER_FLAGS_STRING)" >> "$output_file"
  echo "split_string_into_list(\"\${SANITIZER_FLAGS_STRING}\" SANITIZER_FLAGS_LIST)" >> "$output_file"
  echo "" >> "$output_file"

  # Common compiler flags
  echo "set(STANDARD_FLAGS" >> "$output_file"
  echo "    -Werror" >> "$output_file"
  echo ")" >> "$output_file"
  echo "" >> "$output_file"

  # Loop through targets and set compile options and libraries
  for target in "${targets[@]}"; do
    # Set compiler flags for the target
    echo "# Set compiler flags for the target $target" >> "$output_file"
    echo "target_compile_options($target PRIVATE" >> "$output_file"
    echo "    \${STANDARD_FLAGS}" >> "$output_file"
    echo "    \${WARNING_FLAGS_LIST}" >> "$output_file"
    echo "    \${ANALYZER_FLAGS_LIST}" >> "$output_file"
    echo "    \${DEBUG_FLAGS_LIST}" >> "$output_file"
    echo "    \${SANITIZER_FLAGS_LIST}" >> "$output_file"
    echo ")" >> "$output_file"

    echo "# Add target_link_libraries for $target" >> "$output_file"
    echo "target_link_libraries($target PRIVATE \${SANITIZER_FLAGS_STRING})" >> "$output_file"
    echo "" >> "$output_file"
  done

  echo "find_program(CLANG_FORMAT NAMES \"clang-format\" REQUIRED)" >> "$output_file"
  echo "find_program(CLANG_TIDY NAMES \"clang-tidy\" REQUIRED)" >> "$output_file"
  echo "find_program(CPPCHECK NAMES \"cppcheck\" REQUIRED)" >> "$output_file"
  echo "" >> "$output_file"

  # Format source files using clang-format
  echo "add_custom_target(format" >> "$output_file"
  echo "    COMMAND \${CLANG_FORMAT} --style=file -i \${SOURCES} \${HEADERS}" >> "$output_file"
  echo "    WORKING_DIRECTORY \${CMAKE_SOURCE_DIR}" >> "$output_file"
  echo "    COMMENT \"Running clang-format\"" >> "$output_file"
  echo ")" >> "$output_file"
  echo "" >> "$output_file"

  # Add dependencies for the first target
  echo "add_dependencies($first_target format)" >> "$output_file"
  echo "" >> "$output_file"

  # Add the cppcheck custom command
  echo "add_custom_command(" >> "$output_file"
  echo "    TARGET $first_target POST_BUILD" >> "$output_file"
  echo "    COMMAND \${CLANG_TIDY} \${SOURCES} \${HEADERS} -quiet --warnings-as-errors='*' -checks=*,-llvmlibc-restrict-system-libc-headers,-altera-struct-pack-align,-readability-identifier-length,-altera-unroll-loops,-cppcoreguidelines-init-variables,-cert-err33-c,-modernize-macro-to-enum,-bugprone-easily-swappable-parameters,-clang-analyzer-security.insecureAPI.DeprecatedOrUnsafeBufferHandling,-altera-id-dependent-backward-branch,-concurrency-mt-unsafe,-misc-unused-parameters,-hicpp-signed-bitwise,-google-readability-todo,-cert-msc30-c,-cert-msc50-cpp,-readability-function-cognitive-complexity,-clang-analyzer-security.insecureAPI.strcpy,-cert-env33-c,-android-cloexec-accept,-clang-analyzer-security.insecureAPI.rand,-misc-include-cleaner,-llvmlibc-implementation-in-namespace,-modernize-use-trailing-return-type,-fuchsia-default-arguments-calls,-llvmlibc-callee-namespace,-fuchsia-overloaded-operator,-cert-dcl21-cpp,-cppcoreguidelines-special-member-functions,-hicpp-special-member-functions,-llvm-header-guard,-fuchsia-trailing-return,-performance-avoid-endl -- \${STANDARD_FLAGS} -I/usr/local/include" >> "$output_file"
  echo "    WORKING_DIRECTORY \${CMAKE_SOURCE_DIR}" >> "$output_file"
  echo "    COMMENT \"Running clang-tidy\"" >> "$output_file"
  echo ")" >> "$output_file"
  echo "" >> "$output_file"

  # Check if CMAKE_CXX_COMPILER starts with "clang" and add custom targets
  echo "if (CMAKE_CXX_COMPILER MATCHES \".*/clang.*\")" >> "$output_file"
  echo "    # Add a custom target for clang --analyze" >> "$output_file"
  echo "    add_custom_command(" >> "$output_file"
  echo "        TARGET $first_target POST_BUILD" >> "$output_file"
  echo "        COMMAND \${CMAKE_CXX_COMPILER} --analyzer-output text --analyze -Xclang -analyzer-checker=core --analyze -Xclang -analyzer-checker=deadcode -Xclang -analyzer-checker=security -Xclang -analyzer-disable-checker=security.insecureAPI.DeprecatedOrUnsafeBufferHandling -Xclang -analyzer-checker=unix -Xclang -analyzer-checker=unix \${CMAKE_C_FLAGS} \${STANDARD_FLAGS} \${SOURCES} \${HEADERS}" >> "$output_file"
  echo "        WORKING_DIRECTORY \${CMAKE_SOURCE_DIR}" >> "$output_file"
  echo "        COMMENT \"Running clang --analyze\"" >> "$output_file"
  echo "    )" >> "$output_file"
  echo "" >> "$output_file"
  echo "    # Add a custom command to delete .gch files after the analysis" >> "$output_file"
  echo "    add_custom_command(" >> "$output_file"
  echo "        TARGET main POST_BUILD" >> "$output_file"
  echo "        COMMAND \${CMAKE_COMMAND} -E remove \${CMAKE_SOURCE_DIR}/*.gch" >> "$output_file"
  echo "        COMMENT \"Removing .gch files\"" >> "$output_file"
  echo "    )" >> "$output_file"
  echo "endif ()" >> "$output_file"
  echo "" >> "$output_file"

  # Add a custom target for cppcheck
  echo "add_custom_command(" >> "$output_file"
  echo "    TARGET $first_target POST_BUILD" >> "$output_file"
  echo "    COMMAND \${CPPCHECK} --error-exitcode=1 --force --quiet --library=posix --enable=all --suppress=missingIncludeSystem --suppress=unusedFunction --suppress=unmatchedSuppression \${SOURCES} \${HEADERS}" >> "$output_file"
  echo "    WORKING_DIRECTORY \${CMAKE_SOURCE_DIR}" >> "$output_file"
  echo "    COMMENT \"Running cppcheck\"" >> "$output_file"
  echo ")" >> "$output_file"
  echo "" >> "$output_file"
}

exit $?
