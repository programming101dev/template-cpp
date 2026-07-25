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
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern "C" int LLVMFuzzerInitialize(int *argc, char ***argv)
{
    (void)argc;
    (void)argv;
    (void)freopen("/dev/null", "w", stdout); /* silence display()'s output */
    return 0;
}

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size)
{
    char *s = static_cast<char *>(malloc(size + 1));
    if(s == nullptr)
    {
        return 0;
    }
    memcpy(s, data, size);
    s[size] = '\0';

    display(s); /* <-- EXAMPLE target. Swap for your own input-parsing code. */

    free(s);
    return 0;
}
