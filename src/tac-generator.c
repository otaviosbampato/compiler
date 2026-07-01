#include <stdio.h>

#include "tac-generator.h"

void generate(char *operator, char *argument1, char *argument2, char *result) {
    printf("%s, %s, %s, %s\n",
           operator ? operator : "",
           argument1 ? argument1 : "",
           argument2 ? argument2 : "",
           result ? result : "");
}

void generate_label(char *label_name) {
    printf("label %s\n", label_name ? label_name : "");
}

void generate_return(char *expr) {
    printf("return %s\n", expr ? expr : "");
}