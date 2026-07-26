#include "../include/display.hpp"
#include <cstdlib>
#include <p101_c/p101_stdlib.h>
#include <p101_env/env.h>
#include <p101_error/error.h>

int main()    // NOLINT(modernize-use-trailing-return-type)
{
    p101_error *err;
    p101_env   *env;

    err = p101_error_create(false);
    env = p101_env_create(err, nullptr);
    display(env, err, "Hello, World");
    p101_env_destroy(env);
    p101_error_destroy(err);

    return EXIT_SUCCESS;
}
