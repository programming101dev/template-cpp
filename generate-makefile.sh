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

# Define the function signature as main(void).
main() {
    SUPPORTED_WARNING_FLAGS=$(cat ./flags/"$CC"_warning_flags.txt)
    SUPPORTED_SANITIZER_FLAGS=$(cat ./flags/"$CC"_sanitizer_flags.txt)
    SUPPORTED_ANALYZER_FLAGS=$(cat ./flags/"$CC"_analyzer_flags.txt)
    SUPPORTED_DEBUG_FLAGS=$(cat ./flags/"$CC"_debug_flags.txt)

    # Ensure every function exits with either EXIT_SUCCESS or EXIT_FAILURE.
    local input_file="files.txt"
    local output_file="Makefile"

    # Vigilantly validate function calls for potential errors.
    if [ ! -f "$input_file" ]; then
        echo "Error: Input file '$input_file' not found."
        exit 1
    fi

    # Create the Makefile or append to an existing one
    if [ -f "$output_file" ]; then
        rm "$output_file"
    fi

    touch "$output_file"

    SOURCES=""
    BINARIES=""
    OBJECTS=""

    # Read the input file line by line
    while IFS= read -r line; do
      words=($line)

      for word in "${words[@]}"; do
            if [[ $word == *.cpp ]]; then
                if [ -z "$SOURCES" ]; then
                    SOURCES="$word"  # If sources is empty, no space is added
                else
                    SOURCES="${SOURCES} $word"  # Add a space between file names
                fi
            fi
        done

        if [[ "${words[0]}" != *.o ]]; then
              if [ -z "$BINARIES" ]; then
                  BINARIES="${words[0]}"  # If BINARIES is empty, no space is added
              else
                  BINARIES="${BINARIES} ${words[0]}"  # Add a space between file names
              fi
        else
              if [ -z "$OBJECTS" ]; then
                  OBJECTS="${words[0]}"  # If OBJECTS is empty, no space is added
              else
                  OBJECTS="${OBJECTS} ${words[0]}"  # Add a space between file names
              fi
        fi
    done < "$input_file"

    echo "CC=$CC" >> "$output_file"
    echo -e "COMPILATION_FLAGS=-std=c++20 -D_POSIX_C_SOURCE=200809L -D_XOPEN_SOURCE=700 -D_DEFAULT_SOURCE -D_DARWIN_C_SOURCE -D_GNU_SOURCE -D__BSD_VISIBLE -Werror" >> "$output_file"
    echo -e "SUPPORTED_WARNING_FLAGS=$SUPPORTED_WARNING_FLAGS" >> "$output_file"
    echo -e "SUPPORTED_SANITIZER_FLAGS=$SUPPORTED_SANITIZER_FLAGS" >> "$output_file"
    echo -e "SUPPORTED_ANALYZER_FLAGS=$SUPPORTED_ANALYZER_FLAGS" >> "$output_file"
    echo -e "SUPPORTED_DEBUG_FLAGS=$SUPPORTED_DEBUG_FLAGS" >> "$output_file"
    echo -e "CLANG_TIDY_CHECKS=-checks=*,-llvmlibc-restrict-system-libc-headers,-altera-struct-pack-align,-readability-identifier-length,-altera-unroll-loops,-cppcoreguidelines-init-variables,-cert-err33-c,-modernize-macro-to-enum,-bugprone-easily-swappable-parameters,-clang-analyzer-security.insecureAPI.DeprecatedOrUnsafeBufferHandling,-altera-id-dependent-backward-branch,-concurrency-mt-unsafe,-misc-unused-parameters,-hicpp-signed-bitwise,-google-readability-todo,-cert-msc30-c,-cert-msc50-cpp,-readability-function-cognitive-complexity,-clang-analyzer-security.insecureAPI.strcpy,-cert-env33-c,-android-cloexec-accept,-clang-analyzer-security.insecureAPI.rand,-misc-include-cleaner,-llvmlibc-callee-namespace,-llvmlibc-implementation-in-namespace,-fuchsia-trailing-return,-modernize-use-trailing-return-type,-fuchsia-overloaded-operator" >> "$output_file"
    echo -e "SOURCES=$SOURCES" >> "$output_file"
    echo -e "BINARIES=$BINARIES" >> "$output_file"
    echo -e "OBJECTS=$OBJECTS" >> "$output_file"
    echo "" >> "$output_file"

    # Read the input file line by line
    while IFS= read -r line; do
        # Split the line into words
        words=($line)

        # Check if the line has at least two words
        if [ ${#words[@]} -ge 2 ]; then
            target="${words[0]}"
            dependencies="${words[@]:1}"

            echo "$target: $dependencies" >> "$output_file"

            if [[ $target == *.o ]]; then
                echo -e "\t@\$(CC) \$(COMPILATION_FLAGS) \$(SUPPORTED_WARNING_FLAGS)  \$(SUPPORTED_SANITIZER_FLAGS) \$(SUPPORTED_ANALYZER_FLAGS) \$(SUPPORTED_DEBUG_FLAGS) -c -o \$@ ${words[1]}" >> "$output_file"
            else
                echo -e "\t@\$(CC) \$(SUPPORTED_SANITIZER_FLAGS) -o \$@ \$^" >> "$output_file"
            fi
            echo "" >> "$output_file"
        fi
    done < "$input_file"

    echo "format:" >> "$output_file"
    echo -e "\t@echo \"Formatting source code...\"" >> "$output_file"
	  echo -e "\t@clang-format -i --style=file \$(SOURCES)" >> "$output_file"
    echo "" >> "$output_file"

    echo "tidy:" >> "$output_file"
    echo -e "\t@echo \"Running clang-tidy for static code analysis...\"" >> "$output_file"
	  echo -e "\t@clang-tidy \$(SOURCES) -quiet --warnings-as-errors='*' \$(CLANG_TIDY_CHECKS) -- \$(COMPILATION_FLAGS) \$(CFLAGS) -I/usr/local/include" >> "$output_file"
    echo "" >> "$output_file"

    if [[ "$CC" == *clang* ]]; then
        echo -e "\nanalyze:" >> "$output_file"
        echo -e "\t@echo \"Running $CC for static code analysis...\"" >> "$output_file"
        echo -e "\t@\${CC} --analyze --analyzer-output text -Xclang -analyzer-checker=core --analyze -Xclang -analyzer-checker=deadcode -Xclang -analyzer-checker=security -Xclang -analyzer-disable-checker=security.insecureAPI.DeprecatedOrUnsafeBufferHandling -Xclang -analyzer-checker=unix -Xclang -analyzer-checker=unix -I/usr/local/include \$(CFLAGS) \$(COMPILATION_FLAGS) \$(SOURCES)" >> "$output_file"
    fi

    echo "check:" >> "$output_file"
    echo -e "\t@echo \"Running cppcheck for static code analysis...\"" >> "$output_file"
    echo -e "\t@cppcheck --error-exitcode=1 --force --quiet --inline-suppr --library=posix --enable=all --suppress=missingIncludeSystem --suppress=ConfigurationNotChecked --suppress=unmatchedSuppression -I/usr/local/include \$(SOURCES)" >> "$output_file"
    echo "" >> "$output_file"

    echo "clean:" >> "$output_file"
    echo -e "\trm -f $OBJECTS $BINARIES" >> "$output_file"
    echo "" >> "$output_file"

    echo "all: format $BINARIES tidy check" >> "$output_file"
}

# Call the main function
main
