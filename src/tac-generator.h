#ifndef TAC_GENERATOR_H
#define TAC_GENERATOR_H

typedef struct TAC {
    int unused;
} TAC;

void generate(char *operator, char *argument1, char *argument2, char *result);
void generate_label(char *label_name);
void generate_return(char *expr);

#endif /* TAC_GENERATOR_H */