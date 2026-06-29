#include <stdio.h>

#include "tac.h"

void generate(char *operator, char *argument1, char *argument2, char *result) {
    printf("%s, %s, %s, %s\n",
           operator ? operator : "",
           argument1 ? argument1 : "",
           argument2 ? argument2 : "",
           result ? result : "");
}