extern "C" {
#include "unity.h"
}
#include "../include/display.hpp"
#include <p101_c/p101_stdio.h>
#include <p101_io/io.h>
#include <cstdio>
#include <cstring>

static p101_error *error;
static p101_env   *env;

static void capture_display(const char *msg, char *out, size_t n)
{
    int    saved;
    FILE  *tmp;
    size_t r;

    p101_fflush(env, error, stdout);
    saved = p101_dup(env, error, p101_fileno(env, error, stdout));
    tmp   = p101_tmpfile(env, error);
    p101_dup2(env, error, p101_fileno(env, error, tmp), p101_fileno(env, error, stdout));
    display(env, error, msg);
    p101_fflush(env, error, stdout);
    p101_dup2(env, error, saved, p101_fileno(env, error, stdout));
    p101_close(env, error, saved);
    p101_fseek(env, error, tmp, 0L, SEEK_SET);
    r      = p101_fread(env, error, out, 1, n - 1, tmp);
    out[r] = '\0';
    p101_fclose(env, error, tmp);
}

extern "C" void setUp(void)
{
    error = p101_error_create(false);
    env   = p101_env_create(error, nullptr);
}

extern "C" void tearDown(void)
{
    p101_env_destroy(env);
    p101_error_destroy(error);
}

static void test_display_appends_newline(void)
{
    char b[64];

    capture_display("hello", b, sizeof b);
    TEST_ASSERT_EQUAL_STRING("hello\n", b);
}

static void test_display_empty(void)
{
    char b[64];

    capture_display("", b, sizeof b);
    TEST_ASSERT_EQUAL_STRING("\n", b);
}

int main(void)
{
    UNITY_BEGIN();
    RUN_TEST(test_display_appends_newline);
    RUN_TEST(test_display_empty);
    return UNITY_END();
}
