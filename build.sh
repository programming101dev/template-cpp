#!/usr/bin/env bash
set -euo pipefail

# QoL: -q / --quiet hides the per-file compile-command dump.
_P101_VERBOSE=1
_p101_bq=()
for _p101_bqa in "$@"; do
  case "$_p101_bqa" in
    -q|--quiet) export P101_QUIET=1; _P101_VERBOSE= ;;
    *) _p101_bq+=("$_p101_bqa") ;;
  esac
done
if ((${#_p101_bq[@]})); then set -- "${_p101_bq[@]}"; else set --; fi
unset _p101_bq _p101_bqa


# Defaults
jobs="${JOBS:-${CMAKE_BUILD_PARALLEL_LEVEL:-}}"
target=""
build_dir="build"

usage() {
  echo "Usage: $0 [-j N] [-t <target>] [-q]"
  echo "  -j N        Parallel build with N jobs (or set JOBS / CMAKE_BUILD_PARALLEL_LEVEL)"
  echo "  -t target   Build a specific target (e.g. -t main)"
  echo "  -f, --format Apply clang-tidy --fix (full check set) + clang-format, then exit"
  echo "  -q          Quiet: hide the per-file compile-command dump"
  exit 1
}

# --help / -h -> usage, exit 0 (P101 uniform CLI help)
case " $* " in *" --help "*|*" -h "*) ( usage ) || true; exit 0 ;; esac

# -f / --format : apply clang-tidy --fix (full check set) + clang-format, then
# exit. Resolves the configured build dir on its own (independent of the options
# below) so it works regardless of how this build.sh reads its build dir.
case " $* " in
  *" -f "*|*" --format "*)
    _fbd="build"; [[ -f .last-build-dir ]] && _fbd="$(< .last-build-dir)"
    if [[ ! -d "$_fbd" || ! -f "$_fbd/CMakeCache.txt" ]]; then
      echo "No configured build dir ('$_fbd'). Run ./change-compiler.sh first." >&2
      exit 1
    fi
    echo "Formatting (clang-tidy --fix + clang-format) via target 'format' in '$_fbd'"
    exec cmake --build "$_fbd" --target format
    ;;
esac

# Parse options
while getopts ":j:t:h" opt; do
  case "$opt" in
    j) jobs="$OPTARG" ;;
    t) target="$OPTARG" ;;
    h|*) usage ;;
  esac
done

# Sanity checks
if [[ ! -d "$build_dir" || ! -f "$build_dir/CMakeCache.txt" ]]; then
  echo "You must run ./change-compiler.sh first (no configured build directory found)." >&2
  exit 1
fi

# Assemble build command
cmd=(cmake --build "$build_dir" --clean-first ${_P101_VERBOSE:+--verbose})
[[ -n "$target" ]] && cmd+=(--target "$target")
[[ -n "$jobs" ]] && cmd+=(--parallel "$jobs")

echo "Running: ${cmd[*]}"
exec "${cmd[@]}"
