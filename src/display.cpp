#include "../include/display.hpp"
#include <p101_c/p101_stdio.h>

void display(const p101_env *env, p101_error *err, const char *msg)
{
    p101_printf(env, err, "%s\n", msg);
}
