/*
 * EXAMPLE libFuzzer harness for this template's own code (C++).
 *
 * Same idea as template-c/fuzz/fuzz_display.c: display() only prints, so this
 * finds nothing by design — it shows the MECHANISM and keeps every project
 * fuzz-ready. Point LLVMFuzzerTestOneInput() at your own input-parsing code and
 * the fuzzer + ASan/UBSan start doing real work.
 *
 * NOTE: libFuzzer looks up its callbacks by their C name, so in C++ they MUST be
 * declared extern "C" or the mangled names won't be found. display()'s source is
 * compiled in (see fuzz/CMakeLists.txt) so the harness is coverage-guided.
 */
#include "display.hpp"
#include <p101_c/p101_stdio.h>
#include <p101_c/p101_stdlib.h>
#include <p101_c/p101_string.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

extern "C" int LLVMFuzzerInitialize(int *argc, char ***argv)
{
    p101_error *err;
    p101_env   *env;

    (void)argc;
    (void)argv;
    err = p101_error_create(false);
    env = p101_env_create(err, nullptr);
    (void)p101_freopen(env, err, "/dev/null", "w", stdout); /* silence display()'s output */
    p101_env_destroy(env);
    p101_error_destroy(err);
    return 0;
}

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size)
{
    p101_error *err;
    p101_env   *env;
    char       *s;

    err = p101_error_create(false);
    env = p101_env_create(err, nullptr);
    s   = static_cast<char *>(p101_malloc(env, err, size + 1));
    if(s == nullptr)
    {
        goto done;
    }
    p101_memcpy(env, s, data, size);
    s[size] = '\0';

    display(env, err, s); /* <-- EXAMPLE target. Swap for your own input-parsing code. */

done:
    p101_free(env, s);
    p101_env_destroy(env);
    p101_error_destroy(err);
    return 0;
}
