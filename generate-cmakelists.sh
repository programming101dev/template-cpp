#!/usr/bin/env bash

CC=""

# Function to display usage information
usage() {
    echo "Usage: $0 -c <compiler>"
    exit 1
}

# Parse command-line options
while getopts "c:" opt; do
    case $opt in
        c)
            CC="$OPTARG"
            ;;
        *)
            usage
            ;;
    esac
done

# Check if the -c option has been provided
if [ -z "$CC" ]; then
    echo "Error: -c option is required."
    usage
fi

generate_executable()
{
  local key="$1"

  # Print the key followed by "_SOURCES"
  echo "set(${key}_SOURCES"

  # Loop through .cpp files for the key and echo their paths
  for cpp_file in ${cpp_files[$key]}; do
    echo "    \${CMAKE_SOURCE_DIR}/${cpp_file}"
  done

  # Close the parentheses
  echo ")"
  echo ""

  # Print the key followed by "_HEADERS"
  echo "set(${key}_HEADERS"

  # Loop through .hpp files for the key and echo their paths
  for hpp_file in ${hpp_files[$key]}; do
    echo "    \${CMAKE_SOURCE_DIR}/${hpp_file}"
  done

  # Close the parentheses
  echo ")"
  echo ""
  echo "add_executable(${key} \${${key}_SOURCES} \${${key}_HEADERS})"
}

generate_commands() {
  local -n cpp_array="$1"
  local -n hpp_array="$2"

  # Create variables for all .cpp and .hpp files
  local all_cpp_files=""
  local all_hpp_files=""
  local last_key=""

  # Loop through the associative arrays and combine files
  for key in "${!cpp_array[@]}"; do
    all_cpp_files+=" \${${key}_SOURCES}"
    all_hpp_files+=" \${${key}_HEADERS}"
    last_key="$key"
  done

  echo "find_program(CLANG_FORMAT NAMES \"clang-format\" REQUIRED)"
  echo "find_program(CLANG_TIDY NAMES \"clang-tidy\" REQUIRED)"
  echo "find_program(CPPCHECK NAMES \"cppcheck\" REQUIRED)"
  echo ""
  echo "# Format source files using clang-format"
  echo "add_custom_target(format"
  echo "    COMMAND \${CLANG_FORMAT} --style=file -i ${all_cpp_files} ${all_hpp_files}"
  echo "    WORKING_DIRECTORY \${CMAKE_SOURCE_DIR}"
  echo "    COMMENT \"Running clang-format\""
  echo ")"
  echo ""
  echo "add_dependencies($last_key format)"
  echo ""
  echo "# Lint source files using clang-tidy"
  echo "add_custom_command("
  echo "    TARGET $last_key POST_BUILD"
  echo "    WORKING_DIRECTORY \${CMAKE_SOURCE_DIR}"
  echo "    COMMAND \${CLANG_TIDY} ${all_cpp_files} ${all_hpp_files} -quiet --warnings-as-errors='*' -checks=*,-llvmlibc-restrict-system-libc-headers,-altera-struct-pack-align,-readability-identifier-length,-altera-unroll-loops,-cppcoreguidelines-init-variables,-cert-err33-c,-modernize-macro-to-enum,-bugprone-easily-swappable-parameters,-clang-analyzer-security.insecureAPI.DeprecatedOrUnsafeBufferHandling,-altera-id-dependent-backward-branch,-concurrency-mt-unsafe,-misc-unused-parameters,-hicpp-signed-bitwise,-google-readability-todo,-cert-msc30-c,-cert-msc50-cpp,-readability-function-cognitive-complexity,-clang-analyzer-security.insecureAPI.strcpy,-cert-env33-c,-android-cloexec-accept,-clang-analyzer-security.insecureAPI.rand,-misc-include-cleaner,-llvmlibc-callee-namespace,-llvmlibc-implementation-in-namespace,-fuchsia-trailing-return,-modernize-use-trailing-return-type,-fuchsia-overloaded-operator,-fuchsia-default-arguments-calls,-cert-dcl21-cpp,-llvm-header-guard -- \${CMAKE_C_FLAGS} \${STANDARD_FLAGS} -I\${CMAKE_SOURCE_DIR}/include -I/usr/local/include"
  echo "    COMMENT \"Running clang-tidy\""
  echo ")"
  echo ""
  echo "# Check if CMAKE_CXX_COMPILER starts with \"clang\""
  echo "if (CMAKE_CXX_COMPILER MATCHES \".*/clang.*\")"
  echo "    # Add a custom target for clang --analyze"
  echo "    add_custom_command("
  echo "        TARGET $last_key POST_BUILD"
  echo "        COMMAND \${CMAKE_CXX_COMPILER} --analyzer-output text --analyze -Xclang -analyzer-checker=core --analyze -Xclang -analyzer-checker=deadcode -Xclang -analyzer-checker=security -Xclang -analyzer-disable-checker=security.insecureAPI.DeprecatedOrUnsafeBufferHandling -Xclang -analyzer-checker=unix -Xclang -analyzer-checker=unix \${CMAKE_C_FLAGS} \${STANDARD_FLAGS} ${all_cpp_files} ${all_hpp_files}"
  echo "        WORKING_DIRECTORY \${CMAKE_SOURCE_DIR}"
  echo "        COMMENT \"Running clang --analyze\""
  echo "    )"
  echo "endif()"
  echo ""
  echo "# Add a custom target for cppcheck"
  echo "add_custom_command("
  echo "    TARGET $last_key POST_BUILD"
  echo "    COMMAND \${CPPCHECK} --error-exitcode=1 --force --quiet --library=posix --enable=all --suppress=missingIncludeSystem --suppress=unusedFunction --suppress=unmatchedSuppression ${all_cpp_files} ${all_hpp_files}"
  echo "    WORKING_DIRECTORY \${CMAKE_SOURCE_DIR}"
  echo "    COMMENT \"Running cppcheck\""
  echo ")"
}

generate_compiler()
{
  local key="$1"

  echo "# Set compiler flags for the target ${key}"
  echo "target_compile_options(${key} PRIVATE"
  echo "    \${STANDARD_FLAGS}"
  echo "    \${WARNING_FLAGS_LIST}"
  echo "    \${ANALYZER_FLAGS_LIST}"
  echo "    \${DEBUG_FLAGS_LIST}"
  echo "    \${SANITIZER_FLAGS_LIST}"
  echo ")"
  echo ""
  echo "target_link_libraries(${key} PRIVATE \${SANITIZER_FLAGS_STRING})"
}

# Define the function signature as main(void).
# Define the function signature as main(void).
main()
{
    # Ensure every function exits with either EXIT_SUCCESS or EXIT_FAILURE.
    local input_file="files.txt"
    local output_file="CMakeLists.txt"

    if [ ! -f "$input_file" ]; then
        echo "Error: Input file '$input_file' not found."
        exit 1
    fi

    # Create the CMakeLists-2.txt or append to an existing one
    if [ -f "$output_file" ]; then
        rm "$output_file"
    fi

    touch "$output_file"

    declare -A cpp_files
    declare -A hpp_files

    # Read the input file line by line
    while read -r line; do
      # Split the line into words
      words=($line)

      # Extract the first word as the key
      key=${words[0]}

      # Iterate over the remaining words
      for ((i=1; i<${#words[@]}; i++)); do
        # Determine if it's a .cpp or .hpp file
        file=${words[i]}
        ext="${file##*.}"

        # Add the file to the appropriate array
        if [ "$ext" == "cpp" ]; then
          cpp_files["$key"]+=" $file"
        elif [ "$ext" == "hpp" ]; then
          hpp_files["$key"]+=" $file"
        fi
      done
    done < "$input_file"

    echo "cmake_minimum_required(VERSION 3.12)" >> "$output_file"
    echo "" >> "$output_file"
    echo "project(assign1" >> "$output_file"
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

    # Call the print_values function for each key
    for key in "${!cpp_files[@]}"; do
      generate_executable "$key" >> "$output_file"
    done

    echo "" >> "$output_file"
    echo "# Extract the compiler name without the path" >> "$output_file"
    echo "message(\"C++ Compiler: \${CMAKE_CXX_COMPILER}\")" >> "$output_file"
    echo "get_filename_component(COMPILER_NAME \"\${CMAKE_CXX_COMPILER}\" NAME_WE)" >> "$output_file"
    echo "message(\"COMPILER_NAME: \${COMPILER_NAME}\")" >> "$output_file"
    echo "" >> "$output_file"
    echo "function(split_string_into_list _input_string _output_list)" >> "$output_file"
    echo "    string(REGEX REPLACE \"[ ]+\" \";\" _split_list \"\${_input_string}\")" >> "$output_file"
    echo "    set(\${_output_list} \${_split_list} PARENT_SCOPE)" >> "$output_file"
    echo "endfunction()" >> "$output_file"
    echo "" >> "$output_file"
    echo "# Import warning_flags.txt" >> "$output_file"
    echo "file(STRINGS \"\${CMAKE_SOURCE_DIR}/flags/\${COMPILER_NAME}/warning_flags.txt\" WARNING_FLAGS_STRING)" >> "$output_file"
    echo "split_string_into_list(\"\${WARNING_FLAGS_STRING}\" WARNING_FLAGS_LIST)" >> "$output_file"
    echo "" >> "$output_file"
    echo "# Import analyzer_flags.txt" >> "$output_file"
    echo "file(STRINGS \"\${CMAKE_SOURCE_DIR}/flags/\${COMPILER_NAME}/analyzer_flags.txt\" ANALYZER_FLAGS_STRING)" >> "$output_file"
    echo "split_string_into_list(\"\${ANALYZER_FLAGS_STRING}\" ANALYZER_FLAGS_LIST)" >> "$output_file"
    echo "" >> "$output_file"
    echo "# Import debug_flags.txt" >> "$output_file"
    echo "file(STRINGS \"\${CMAKE_SOURCE_DIR}/flags/\${COMPILER_NAME}/debug_flags.txt\" DEBUG_FLAGS_STRING)" >> "$output_file"
    echo "split_string_into_list(\"\${DEBUG_FLAGS_STRING}\" DEBUG_FLAGS_LIST)" >> "$output_file"
    echo "" >> "$output_file"
    echo "# Import sanitizer_flags.txt" >> "$output_file"
    echo "file(STRINGS \"\${CMAKE_SOURCE_DIR}/flags/\${COMPILER_NAME}/sanitizer_flags.txt\" SANITIZER_FLAGS_STRING)" >> "$output_file"
    echo "split_string_into_list(\"\${SANITIZER_FLAGS_STRING}\" SANITIZER_FLAGS_LIST)" >> "$output_file"
    echo "" >> "$output_file"
    echo "# Common compiler flags" >> "$output_file"
    echo "set(STANDARD_FLAGS" >> "$output_file"
    echo "    -Werror" >> "$output_file"
    echo ")" >> "$output_file"
    echo "" >> "$output_file"

    generate_commands cpp_files hpp_files >> "$output_file"
    echo "" >> "$output_file"

    for key in "${!cpp_files[@]}"; do
      generate_compiler "$key" >> "$output_file"
      echo "" >> "$output_file"
    done
}

# Call the main function
main
