# Commands

Quick reference for this template. Every script also supports `--help`.
Run `cmake -S . -B build -DCMAKE_C_COMPILER=<compiler> -DP101_BUILD_LEVEL=1` once before building.

| Command | What it does |
| --- | --- |
| `cmake -S . -B build -DCMAKE_CXX_COMPILER=<cc> -DP101_BUILD_LEVEL=1` | Configure the build with a compiler (also `set CMAKE_C_COMPILER=<cc>`). `--help` lists detected compilers. |
| `cmake -S . -B build -DCMAKE_CXX_COMPILER=<cc> -DP101_BUILD_LEVEL=1 -s address,undefined` | Configure with specific sanitizers |
| `cmake -S . -B build -DCMAKE_CXX_COMPILER=<cc> -DP101_BUILD_LEVEL=1 --coverage` | Configure an instrumented build for coverage (gcov) |
| `cmake --build build` | Strict analysis build: format-check, clang-tidy, cppcheck, static analyzer, `-Werror`, sanitizers. `-q` = quiet |
| `cmake --build build --target format` | Auto-fix in place: clang-tidy `--fix` + clang-format |
| `clang-format --dry-run --Werror -style=file <sources>` | Format check only, no build (hook-friendly); non-zero if unclean |
| `cmake -S . -B build -DP101_BUILD_LEVEL=3 && cmake --build build` | **The gate:** format + strict build + tests + fuzz smoke -> one PASS/FAIL. `--cov <pct>` adds a coverage gate |
| `cmake -S . -B build -DP101_BUILD_LEVEL=2 && cmake --build build` | Build & run the Unity test suite (ctest) |
| `../../scripts/update-all.sh --level 2` | Run the tests across every supported compiler |
| `configure and run the fuzz/ CMake project` | Run the libFuzzer target (coverage-guided + sanitizers); PASS/FAIL. `-t <secs>` sets the time budget |
| `configure with -DP101_COVERAGE_MODE=ON and run gcovr` | HTML coverage report. `--report-only` skips the run; `--min <pct>` fails under a threshold |
| `configure with -DP101_COVERAGE_MODE=ON and run gcovr` \| `profile` | One entry point for the coverage / profiling reports |
| `cmake -S . -B build` | Report what toolchain/features actually work on this machine for this project |
| `cmake --build build --target clean` | Remove `build-` / `coverage-` / `profile-` output (`-n` previews) |
| `./copy-template.sh <dir>` | Start a new project from this template |

Less common: `../../scripts/update-all.sh --level 1` (build with every compiler), `cmake -S . -B build`
(detect installed compilers), `cmake -S . -B build` (verify required tools).
