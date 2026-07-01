#ifndef UTILS_H
#define UTILS_H

#include <stddef.h>

#include "symtable.h"
#include "temporary.h"

#include "tac-generator.h"

int max(int t1, int t2);
char *widen(char *addr, int t1, int t2);
void output_code(char *code);

#endif