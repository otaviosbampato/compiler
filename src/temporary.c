#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "temporary.h"

static unsigned long temporary_counter = 0;

Temporary *temporary_new(void) {
    Temporary *temporary = (Temporary*)malloc(sizeof(Temporary));
    if (!temporary) {
        perror("temporary_new: malloc");
        exit(1);
    }

    snprintf(temporary->name, sizeof(temporary->name), "t%lu", temporary_counter++);

    return temporary;
}

void temporary_free(Temporary *temporary) {
    if (!temporary) {
        return;
    }
    free(temporary);
}

const char *temporary_get_name(const Temporary *temporary) {
    return temporary ? temporary->name : NULL;
}