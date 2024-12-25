#!/usr/bin/env bash

cxx_compiler=""
clang_format_name="clang-format"
clang_tidy_name="clang-tidy"
cppcheck_name="cppcheck"
sanitizers=""

# Function to display script usage
usage()
{
    echo "Usage: $0 -c <c compiler> [-f <clang-format>] [-t <clang-tidy>] [-k <cppcheck>] [-s <sanitizers>]"
    echo "  -c c++ compiler   Specify the c++ compiler name (e.g. gcc or clang)"
    echo "  -f clang-format   Specify the clang-format name (e.g. clang-tidy or clang-tidy-17)"
    echo "  -t clang-tidy     Specify the clang-tidy name (e.g. clang-tidy or clang-tidy-17)"
    echo "  -k cppcheck       Specify the cppcheck name (e.g. cppcheck)"
    echo "  -s sanitizers     Specify the sanitizers to use name (e.g. address,undefined)"
    exit 1
}

# Parse command-line options using getopt
while getopts ":c:f:t:k:s:" opt; do
  case $opt in
    c)
      cxx_compiler="$OPTARG"
      ;;
    f)
      clang_format_name="$OPTARG"
      ;;
    t)
      clang_tidy_name="$OPTARG"
      ;;
    k)
      cppcheck_name="$OPTARG"
      ;;
    s)
      sanitizers="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      usage
      ;;
  esac
done

# Check if the compiler argument is provided
if [ -z "$cxx_compiler" ]; then
  echo "Error: c++ compiler argument (-c) is required."
  usage
fi

./check-env.sh -c "$cxx_compiler" -f "$clang_format_name" -t "$clang_tidy_name" -k "$cppcheck_name"

if [ ! -f "supported_cxx_compilers.txt" ] || ! grep -Fxq "$cxx_compiler" supported_cxx_compilers.txt; then
   ./check-compilers.sh
fi

if [ ! -d "./.flags/$cxx_compiler" ]; then
    ./generate-flags.sh
fi

echo "Sanitizers = $sanitizers"

# Split the sanitizers string and construct flags
IFS=',' read -ra SANITIZERS <<< "$sanitizers"
for sanitizer in "${SANITIZERS[@]}"; do
    sanitizer_flags+="-DSANITIZER_${sanitizer}=ON "
done

rm -rf build/CMakeCache.txt
cmake -S . -B build -DCMAKE_CXX_COMPILER="$cxx_compiler" -DCLANG_FORMAT_NAME="$clang_format_name" -DCLANG_TIDY_NAME="$clang_tidy_name" -DCPPCHECK_NAME="$cppcheck_name" $sanitizer_flags -DCMAKE_BUILD_TYPE=Debug -DCMAKE_OSX_SYSROOT=""
