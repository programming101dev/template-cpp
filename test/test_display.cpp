extern "C" {
#include "unity.h"
}
#include "../include/display.hpp"
#include <cstdio>
#include <cstring>
#include <unistd.h>

static void capture_display(const char *msg, char *out, size_t n){
    std::fflush(stdout);
    int saved = dup(fileno(stdout));
    FILE *tmp = tmpfile();
    dup2(fileno(tmp), fileno(stdout));
    display(msg);
    std::fflush(stdout);
    dup2(saved, fileno(stdout)); close(saved);
    std::rewind(tmp);
    size_t r = std::fread(out, 1, n-1, tmp); out[r]='\0'; std::fclose(tmp);
}
extern "C" void setUp(void) {}
extern "C" void tearDown(void) {}
static void test_display_appends_newline(void){ char b[64]; capture_display("hello", b, sizeof b); TEST_ASSERT_EQUAL_STRING("hello\n", b); }
static void test_display_empty(void){ char b[64]; capture_display("", b, sizeof b); TEST_ASSERT_EQUAL_STRING("\n", b); }
int main(void){ UNITY_BEGIN(); RUN_TEST(test_display_appends_newline); RUN_TEST(test_display_empty); return UNITY_END(); }
