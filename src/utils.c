#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "utils.h"

#define output_file_path "output/output.txt"

//retorna um valor inteiro representando a hierarquia de tipos
static int type_rank(int type) {
    switch (type) {
        case SYM_TYPE_BOOL:
            return 0;
        case SYM_TYPE_INT:
            return 1;
        case SYM_TYPE_FLOAT:
            return 2;
        default:
            return -1;
    }
}

// retorna o menor limite superior entre dois tipos na hierarquia: boolean -> int -> float
int max(int t1, int t2) {
    int r1 = type_rank(t1);
    int r2 = type_rank(t2);

    if (r1 < 0) {
        fprintf(stderr, "Erro: tipo invalido em max(%d, %d)\n", t1, t2);
        return t2;
    }

    if (r2 < 0) {
        fprintf(stderr, "Erro: tipo invalido em max(%d, %d)\n", t1, t2);
        return t1;
    }

    return (r1 >= r2) ? t1 : t2;
}

// Faz widening de um address textual quando t1 < t2.
// t1 == t2 retorna o próprio addr
char *widen(char *addr, int t1, int t2) {
    int r1 = type_rank(t1);
    int r2 = type_rank(t2);

    if (!addr) {
        fprintf(stderr, "Erro: address nulo em widen(%d, %d)\n", t1, t2);
        return NULL;
    }

    if (r1 < 0 || r2 < 0) {
        fprintf(stderr, "Erro: tipo invalido em widen(%d, %d)\n", t1, t2);
        return addr;
    }

    if (r1 == r2) {
        return addr;
    }

    if (r1 > r2) {
        fprintf(stderr,
                "Erro: widening invalido em widen(%d, %d); t1 deve ser menor que t2\n",
                t1, t2);
        return addr;
    }

    const char *cast = NULL;
    switch (t2) {
        case SYM_TYPE_INT:
            cast = "(int)";
            break;
        case SYM_TYPE_FLOAT:
            cast = "(float)";
            break;
        default:
            fprintf(stderr, "Erro: tipo de destino invalido em widen(%d, %d)\n", t1, t2);
            return addr;
    }

    Temporary *temporary = temporary_new();
    if (!temporary) {
        fprintf(stderr, "Erro: nao foi possivel criar temporario em widen(%d, %d)\n", t1, t2);
        return addr;
    }

    generate("=", (char *)cast, addr, (char *)temporary_get_name(temporary));

    char *result = strdup(temporary_get_name(temporary));
    temporary_free(temporary);

    if (!result) {
        perror("widen: strdup");
        return addr;
    }

    return result;
}

void output_code(char *code) {
    if (!code) {
        fprintf(stderr, "Erro: código nulo em output_code\n");
        return;
    }
    FILE *fptr;

    fptr = fopen(output_file_path, "w");

    if (fptr == NULL) {
        printf("Error opening the file!\n");
        return; 
    }

    fprintf(fptr, "%s", code);
    fclose(fptr);
    return;
}