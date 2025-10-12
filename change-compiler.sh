#!/usr/bin/env bash
# change-compiler.sh — configure a C++ project with a chosen compiler & tools
set -euo pipefail

# ----------------- defaults -----------------
cxx_compiler=""      # passed via -c (e.g. g++, g++-15, clang++)
clang_format_name="clang-format"
clang_tidy_name="clang-tidy"
cppcheck_name="cppcheck"
sanitizers=""
sanitizers_passed=false

build_dir="build"
generator=""         # e.g. "Ninja" or "Unix Makefiles"
reuse_build=false    # -R=reuse build dir instead of wiping it
extra_cmake_args=()  # additional -Dfoo=bar etc.

# ----------------- usage -----------------
usage() {
  cat <<'USAGE' >&2
Usage: change-compiler.sh -c <cxx> [-f <clang-format>] [-t <clang-tidy>] [-k <cppcheck>] [-s <sanitizers>] [-b <build-dir>] [-G <generator>] [-R] [-- -D...]
  -c <cxx>         C++ compiler (e.g. g++, g++-15, clang++)
  -f <name>        clang-format executable (default: clang-format)
  -t <name>        clang-tidy executable   (default: clang-tidy)
  -k <name>        cppcheck executable     (default: cppcheck)
  -s <list>        comma list of sanitizers (e.g. address,undefined)
                   If omitted, reads sanitizers.txt (if present), else none.
  -b <dir>         build directory (default: build)
  -G <gen>         CMake generator (e.g. Ninja, "Unix Makefiles")
  -R               reuse existing build dir (do NOT delete ./build)
  --               pass remaining args straight to CMake (e.g., -DVAR=ON)

Examples:
  ./change-compiler.sh -c clang++
  ./change-compiler.sh -c g++-15 -s address,undefined -G Ninja
  ./change-compiler.sh -c clang++ -- -DP101_STRICT=ON
USAGE
  exit 1
}

# ----------------- args -----------------
while (("$#")); do
  case "$1" in
    -c) cxx_compiler="${2-}"; shift 2 ;;
    -f) clang_format_name="${2-}"; shift 2 ;;
    -t) clang_tidy_name="${2-}"; shift 2 ;;
    -k) cppcheck_name="${2-}"; shift 2 ;;
    -s) sanitizers="${2-}"; sanitizers_passed=true; shift 2 ;;
    -b) build_dir="${2-}"; shift 2 ;;
    -G) generator="${2-}"; shift 2 ;;
    -R) reuse_build=true; shift ;;
    --) shift; extra_cmake_args+=("$@"); break ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

# ----------------- validation -----------------
[[ -n "$cxx_compiler" ]] || { echo "Error: -c <cxx> (C++ compiler) is required." >&2; usage; }

# Resolve a tool to PATH (name or absolute path is fine)
must_find() {
  local tool="$1"
  if [[ "$tool" = /* ]]; then
    [[ -x "$tool" ]] || { echo "Error: '$tool' not executable" >&2; exit 2; }
    printf '%s\n' "$tool"
  else
    command -v "$tool" 2>/dev/null || { echo "Error: '$tool' not found in PATH" >&2; exit 2; }
  fi
}

CXX_PATH="$(must_find "$cxx_compiler")"
CLANG_FORMAT_PATH="$(must_find "$clang_format_name")"
CLANG_TIDY_PATH="$(must_find "$clang_tidy_name")"
CPPCHECK_PATH="$(must_find "$cppcheck_name")"

# ----------------- sanitizers -----------------
if ! $sanitizers_passed; then
  if [[ -f "sanitizers.txt" ]]; then
    # Strip comments and whitespace
    sanitizers="$(sed 's/#.*$//g' sanitizers.txt | tr -d '[:space:]')"
    echo "Sanitizers loaded from sanitizers.txt: ${sanitizers:-<none>}"
  else
    sanitizers=""
    echo "No -s and no sanitizers.txt found. Using no sanitizers."
  fi
else
  echo "Sanitizers specified via command-line: ${sanitizers:-<none>}"
fi

# Friendly tweak for macOS AppleClang/leak (CMake will enforce final compatibility)
if [[ "$(uname -s)" == "Darwin" ]]; then
  if "$CXX_PATH" --version 2>/dev/null | grep -qi "clang"; then
    : # leave list as-is; CMakeLists handles sanitizer support
  fi
fi

# ----------------- build dir -----------------
if ! $reuse_build; then
  rm -rf "$build_dir"
fi
mkdir -p "$build_dir"

# ----------------- banner -----------------
echo "Configuring with:"
echo "  CXX              = $CXX_PATH"
echo "  clang-format     = $CLANG_FORMAT_PATH"
echo "  clang-tidy       = $CLANG_TIDY_PATH"
echo "  cppcheck         = $CPPCHECK_PATH"
echo "  sanitizers       = ${sanitizers:-<none>}"
echo "  build dir        = $build_dir"
[[ -n "$generator" ]] && echo "  generator        = $generator"

# ----------------- cmake configure -----------------
cmake_args=(
  -S . -B "$build_dir"
  -DCMAKE_CXX_COMPILER="$CXX_PATH"
  -DCLANG_FORMAT_NAME="$CLANG_FORMAT_PATH"
  -DCLANG_TIDY_NAME="$CLANG_TIDY_PATH"
  -DCPPCHECK_NAME="$CPPCHECK_PATH"
  -DSANITIZER_LIST="$sanitizers"
  -DCMAKE_BUILD_TYPE=Debug
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
)

# Generator if provided
if [[ -n "$generator" ]]; then
  cmake_args+=(-G "$generator")
fi

# Extra -D… after --
if ((${#extra_cmake_args[@]})); then
  cmake_args+=("${extra_cmake_args[@]}")
fi

echo "Running: cmake ${cmake_args[*]}"
cmake "${cmake_args[@]}"

echo "Done. Now run:  ./build.sh"
