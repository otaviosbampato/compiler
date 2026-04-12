%option yylineno
%option noyywrap

%{
#include <stdio.h>
#include <stdlib.h>

int yyval;
int column_number = 1;


/* Auxiliary Functions */

void resetColumnCounter() {
    column_number = 1;
}

void incrementColumnCounter(int increment) {
    column_number += increment;
}

void printLexema(char *lexema, char *tokenClass){
  fprintf(yyout,"%d(%d): %s (%s)\n", yylineno,column_number,yytext, tokenClass);
}

/* Hash Declaration and Auxiliary Functions */

#define TAM_TABELA 211  // tamanho da hash (número primo aumenta dispersão)

/* Estrutura do símbolo */
typedef struct simbolo {
    char *lexema;           // lexema string
    char *tokenClass;        // token class (identifier)
    int linha;              // lexema line
    int coluna;             // lexema column
    struct simbolo *prox;   // para colisões da hash (linked list)
} Simbolo;

Simbolo* tabela[TAM_TABELA] = {NULL};

/* Função hash */
unsigned int hash(const char *lexema) {
    unsigned int h = 0;
    while (*lexema) {
        h = (h << 4) + *lexema++;
        unsigned int g = h & 0xF0000000L;
        if (g) h ^= g >> 24;
        h &= ~g;
    }
    return h % TAM_TABELA;
}

/* Busca símbolo */
Simbolo* buscar(const char* lexema) {
    unsigned int pos = hash(lexema);
    for (Simbolo* currentSymbolPtr = tabela[pos]; currentSymbolPtr != NULL; currentSymbolPtr = currentSymbolPtr->prox) {
        if (strcmp(currentSymbolPtr->lexema, lexema) == 0) return currentSymbolPtr;
    }
    return NULL;
}

/* Insere símbolo */
void inserir(const char* lexema, const char* tokenClass, int line, int column) {
    if (buscar(lexema) != NULL) return; // evita duplicatas
    unsigned int h = hash(lexema);
    Simbolo* newSymbol = (Simbolo*) malloc(sizeof(Simbolo));
    newSymbol->lexema = strdup(lexema);
    newSymbol->tokenClass = strdup(tokenClass);
    newSymbol->line = line;
    newSymbol->column = column;
    newSymbol->prox = tabela[h];
    tabela[h] = newSymbol;
}

%}

/* Regex Definitions  */

ws                      [ \t]+
newline                 [\n]
digit                   [0-9]
letter                  [a-zA-Z]
float                   ([-+])?({digit}+\.{digit}*|\.{digit}+)
integer                 ([-+])?{digit}+
identifier              [a-zA-Z]([a-zA-Z0-9_]*[a-zA-Z0-9])? 
singleLineComment       \/\/[^\n]*
multilineComment        \/\*([^*]|\*+[^*/])*\*+\/
invalidSequence         [^a-zA-Z0-9_ \t\n]+

%%

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Ignorable Symbols −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

{ws} { incrementColumnCounter(yyleng); }

{newline} { resetColumnCounter(); }

{singleLineComment} { incrementColumnCounter(yyleng); } 

{multilineComment} { incrementColumnCounter(yyleng); }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Keywords −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

if      { printLexema(yytext, "IF"); incrementColumnCounter(yyleng);    }
else    { printLexema(yytext, "ELSE"); incrementColumnCounter(yyleng);  }
while   { printLexema(yytext, "WHILE"); incrementColumnCounter(yyleng); }
print   { printLexema(yytext, "PRINT"); incrementColumnCounter(yyleng); }
read    { printLexema(yytext, "READ"); incrementColumnCounter(yyleng);  }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Type Definitions −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

int    { printLexema(yytext, "TYPE_INT"); incrementColumnCounter(yyleng);   }
float  { printLexema(yytext, "TYPE_FLOAT"); incrementColumnCounter(yyleng); }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Relational Operators −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

"<="    { printLexema(yytext, "RELOP_LE"); incrementColumnCounter(yyleng); }
">="    { printLexema(yytext, "RELOP_GE"); incrementColumnCounter(yyleng); }
"!="    { printLexema(yytext, "RELOP_NE"); incrementColumnCounter(yyleng); }
"=="    { printLexema(yytext, "RELOP_EQ"); incrementColumnCounter(yyleng); }
"<"     { printLexema(yytext, "RELOP_LT"); incrementColumnCounter(yyleng); }
">"     { printLexema(yytext, "RELOP_GT"); incrementColumnCounter(yyleng); }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Assignment Operators −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

"="     { printLexema(yytext, "ATT_OP"); incrementColumnCounter(yyleng); }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Arithmetic Operators −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

"+"     { printLexema(yytext, "PLUS"); incrementColumnCounter(yyleng);  }
"-"     { printLexema(yytext, "MINUS"); incrementColumnCounter(yyleng); }
"**"    { printLexema(yytext, "POW"); incrementColumnCounter(yyleng); }
"*"     { printLexema(yytext, "DOT"); incrementColumnCounter(yyleng); }
"/"     { printLexema(yytext, "DIV"); incrementColumnCounter(yyleng); }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Logical Operators −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

"&&"    { printLexema(yytext, "AND"); incrementColumnCounter(yyleng); }
"||"    { printLexema(yytext, "OR"); incrementColumnCounter(yyleng);  }
"~"     { printLexema(yytext, "NEG"); incrementColumnCounter(yyleng); }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Punctuation Symbols −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

";"     { printLexema(yytext, "SC"); incrementColumnCounter(yyleng); }
","     { printLexema(yytext, "COMMA"); incrementColumnCounter(yyleng); }
"("     { printLexema(yytext, "OPEN_PAR"); incrementColumnCounter(yyleng); }
")"     { printLexema(yytext, "CLOSE_PAR"); incrementColumnCounter(yyleng); }
"{"     { printLexema(yytext, "OPEN_BRACKET"); incrementColumnCounter(yyleng); }
"}"     { printLexema(yytext, "CLOSE_BRACKET"); incrementColumnCounter(yyleng); }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Identifiers and Numbers −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

{identifier} { printLexema(yytext, "ID"); incrementColumnCounter(yyleng); }

{float} { printLexema(yytext, "FLOAT"); incrementColumnCounter(yyleng); }

{integer} { printLexema(yytext, "INTEGER"); incrementColumnCounter(yyleng); }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Errors −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

{invalidSequence} { printLexema(yytext, "ERROR"); incrementColumnCounter(yyleng); }

. { printLexema(yytext, "ERROR"); incrementColumnCounter(yyleng); }

%%

int main(int argc, char **argv) {

    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            perror("Error opening file");
            return 1;
        }
    }
    
    yylex();
    return 0;
}