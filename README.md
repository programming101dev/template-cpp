# template-cxx

`template-cxx` is a minimal C++ program that prints a message. Like every Programming 101 template it ships with the full
quality toolchain already wired in — a strict analysis build, the sanitizers,
unit tests, a fuzzer, and coverage — so any project you start from it is
correct-by-construction from the first commit. `commands.md` is the one-line
reference for every script; this file is the walkthrough.

## Quick start

Configure a compiler once, then run the gate:

    cmake -S . -B build -DCMAKE_CXX_COMPILER=clang++ -DP101_BUILD_LEVEL=1     # pick the compiler and configure the build
    cmake -S . -B build -DP101_BUILD_LEVEL=3 && cmake --build build                       # format + strict build + tests + fuzz smoke -> one PASS/FAIL

`cmake --help` lists the compilers detected on this machine.

## The workflow

1. **Configure** — `cmake -S . -B build -DCMAKE_CXX_COMPILER=clang++ -DP101_BUILD_LEVEL=1` picks the compiler and
   configures the build. Run it again any time to switch compilers (e.g.
   `cmake -S . -B build -DCMAKE_CXX_COMPILER=g++ -DP101_BUILD_LEVEL=1`).
2. **Build** — `cmake --build build` compiles through the strict analysis pipeline:
   clang-format check, clang-tidy, cppcheck, the Clang static analyzer,
   hundreds of warnings under `-Werror`, and the sanitizers baked in. Add `-q`
   to hide the per-file command dump.
3. **Test** — `cmake -S . -B build -DP101_BUILD_LEVEL=2 && cmake --build build` builds and runs the Unity test suite; `../../scripts/update-all.sh --level 2`
   runs it across every supported compiler.
4. **Check** — `cmake -S . -B build -DP101_BUILD_LEVEL=3 && cmake --build build` is the one command to run before you submit: it does
   the format check, the strict build, the tests, and a short fuzz smoke run,
   then prints a single PASS/FAIL and exits non-zero on any failure. Add
   `--cov <pct>` to also fail when test
   coverage is below a threshold.
5. **Fuzz** — `configure and run the fuzz/ CMake project` runs the libFuzzer target (coverage-guided, sanitizers
   on) and prints PASS/FAIL. Here it fuzzes `display()` as a worked *example* — it finds nothing by design. Point the harness at your own input-parsing code (see `fuzz/fuzz_display.cpp`) and the fuzzer + sanitizers start earning their keep.
6. **Coverage** — `configure with -DP101_COVERAGE_MODE=ON and run gcovr` builds an HTML coverage report; add
   `--min <pct>` to fail below a threshold.
7. **Diagnose** — when the local toolchain looks wrong, `cmake -S . -B build` reports
   what actually works on this machine for this project.

## Formatting

    cmake --build build --target format     # apply clang-tidy --fix + clang-format, in place
    clang-format --dry-run --Werror -style=file <sources>     # check formatting only, no build (non-zero if unclean)

## Adding or removing files

This template uses a fixed strict `CMakeLists.txt` driven by `config.cmake` —
there is no generated makefile to edit. When you add or remove a source or
header, edit the lists in `config.cmake` (`main_SOURCES`, `main_HEADERS`, and
`main_LINK_LIBRARIES` for libraries), then re-configure and build:

    cmake -S . -B build -DCMAKE_CXX_COMPILER=clang++ -DP101_BUILD_LEVEL=1
    cmake --build build

## Start a new project from this template

    ./copy-template.sh <destination-directory>

This copies everything you need — the sources, the build system, and every
script — into a fresh project directory.

## Prerequisites

The Programming 101 setup scripts install everything these tools need. If a
script reports a missing tool, run `cmake -S . -B build` to see exactly what this
project can and can't do on your machine, and re-run the setup if needed.
