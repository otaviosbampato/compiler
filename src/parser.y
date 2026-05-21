%{
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

int yylex(void);

void yyerror(const char *s);

%}

%token DIGIT /*Vemdo analisador léxico*/

%%
line : expr '\n' { printf("%d\n", $1); }
;

expr : expr '+' term { $$ = $1 + $3; }
| term
;

term : term '*' factor { $$ = $1 * $3; }
| factor
;

factor : '(' expr ')' { $$ = $2; }
| DIGIT
;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

extern void printSymbolTable(); // func do lexer pra printar a tabela
int main(int argc, char **argv) {
    extern FILE *yyin;
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            perror("Error opening file");
            return 1;
        }
    }
    // roda o parsing, que por sua vez roda o lex
    yyparse();
    
    // printa a tabela de símbolos
    printSymbolTable();

    return 0;
}