%option yylineno
%option noyywrap

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.h"

int column_number = 1;

#define TYPE_INT 1
#define TYPE_FLOAT 2
#define EQOP_NE 1
#define EQOP_EQ 2
#define RELOP_LE 1
#define RELOP_GE 2
#define RELOP_LT 3
#define RELOP_GT 4
#define NUMBER_INT 1
#define NUMBER_FLOAT 2


/* Auxiliary Functions */

void resetColumnCounter() {
    column_number = 1;
}

void incrementColumnCounter(int increment) {
    column_number += increment;
}

void printLexeme(char *lexeme, char *tokenClass){
  fprintf(yyout,"%d(%d): %s (%s)\n", yylineno,column_number,yytext, tokenClass);
}

/* Hash Declaration and Auxiliary Functions */

#define TABLE_SIZE 211  // tamanho da hash (número primo aumenta dispersão)

int symbol_count = 1;

/* Symbol table - declarada e gerenciada aqui no lexer */
Symbol* table[TABLE_SIZE] = {NULL};

/* Função hash */
unsigned int hash(const char *lexeme) {
    unsigned int h = 0;
    while (*lexeme) {
        h = (h << 4) + *lexeme++;
        unsigned int g = h & 0xF0000000L;
        if (g) h ^= g >> 24;
        h &= ~g;
    }
    return h % TABLE_SIZE;
}

/* Busca símbolo */
Symbol* searchTable(const char* lexeme) {
    unsigned int pos = hash(lexeme);
    for (Symbol* currentSymbolPtr = table[pos]; currentSymbolPtr != NULL; currentSymbolPtr = currentSymbolPtr->next) {
        if (strcmp(currentSymbolPtr->lexeme, lexeme) == 0) return currentSymbolPtr;
    }
    return NULL;
}

/* Insere símbolo */
void insertTable(const char* lexeme, const char* tokenClass, int line, int column) {
    if (searchTable(lexeme) != NULL) return; // evita duplicatas
    unsigned int h = hash(lexeme);
    Symbol* newSymbol = (Symbol*) malloc(sizeof(Symbol));
    newSymbol->pos = symbol_count++;
    newSymbol->lexeme = strdup(lexeme);
    newSymbol->tokenClass = strdup(tokenClass);
    newSymbol->line = line;
    newSymbol->column = column;
    newSymbol->value = 0.0;
    newSymbol->next = table[h];
    table[h] = newSymbol;
}

%}

/* Regex Definitions  */

ws                      [ \t]+
newline                 [\n]
digit                   [0-9]
float                   ({digit}+\.{digit}*|\.{digit}+)
integer                 {digit}+
identifier              [a-zA-Z]([a-zA-Z0-9_]*[a-zA-Z0-9])? 
singleLineComment       \/\/[^\n]*
multilineComment        \/\*([^*]|\*+[^*/])*\*+\/

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

if      { printLexeme(yytext, "IF"); incrementColumnCounter(yyleng); return IF; }
else    { printLexeme(yytext, "ELSE"); incrementColumnCounter(yyleng); return ELSE; }
while   { printLexeme(yytext, "WHILE"); incrementColumnCounter(yyleng); return WHILE; }
print   { printLexeme(yytext, "PRINT"); incrementColumnCounter(yyleng); return PRINT; }
read    { printLexeme(yytext, "READ"); incrementColumnCounter(yyleng); return READ; }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Type Definitions −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

int    { yylval.num = TYPE_INT; printLexeme(yytext, "TYPE (TYPE_INT)"); incrementColumnCounter(yyleng); return TYPE; }
float  { yylval.num = TYPE_FLOAT; printLexeme(yytext, "TYPE (TYPE_FLOAT)"); incrementColumnCounter(yyleng); return TYPE; }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Relational Operators −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

"<="    { yylval.num = RELOP_LE; printLexeme(yytext, "RELOP (RELOP_LE)"); incrementColumnCounter(yyleng); return RELOP; }
">=" { yylval.num = RELOP_GE; printLexeme(yytext, "RELOP (RELOP_GE)"); incrementColumnCounter(yyleng); return RELOP; }
"!="    { yylval.num = EQOP_NE; printLexeme(yytext, "EQOP (EQOP_NE)"); incrementColumnCounter(yyleng); return EQOP; }
"==" { yylval.num = EQOP_EQ; printLexeme(yytext, "EQOP (EQOP_EQ)"); incrementColumnCounter(yyleng); return EQOP; }
"<"     { yylval.num = RELOP_LT; printLexeme(yytext, "RELOP (RELOP_LT)"); incrementColumnCounter(yyleng); return RELOP; }
">"     { yylval.num = RELOP_GT; printLexeme(yytext, "RELOP (RELOP_GT)"); incrementColumnCounter(yyleng); return RELOP; }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Assignment Operators −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

"="     { printLexeme(yytext, "ASSIGN_OP"); incrementColumnCounter(yyleng); return ASSIGN; }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Arithmetic Operators −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

"+"     { printLexeme(yytext, "ARITH_OP_ADD"); incrementColumnCounter(yyleng); return PLUS; }
"-"     { printLexeme(yytext, "ARITH_OP_SUB"); incrementColumnCounter(yyleng); return MINUS; }
"**"    { printLexeme(yytext, "ARITH_OP_POW"); incrementColumnCounter(yyleng); return POW; }
"*"     { printLexeme(yytext, "ARITH_OP_MUL"); incrementColumnCounter(yyleng); return MULT; }
"/"     { printLexeme(yytext, "ARITH_OP_DIV"); incrementColumnCounter(yyleng); return DIV; }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Logical Operators −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

"&&"    { printLexeme(yytext, "AND"); incrementColumnCounter(yyleng); return AND; }
"||"    { printLexeme(yytext, "OR"); incrementColumnCounter(yyleng); return OR; }
"~"     { printLexeme(yytext, "NOT"); incrementColumnCounter(yyleng); return NOT; }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Punctuation Symbols −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

";"     { printLexeme(yytext, "PUNCT_SEMICOLON"); incrementColumnCounter(yyleng); return PUNCT_SEMICOLON; }
","     { printLexeme(yytext, "PUNCT_COMMA"); incrementColumnCounter(yyleng); return PUNCT_COMMA; }
"("     { printLexeme(yytext, "PUNCT_OPEN_PAREN"); incrementColumnCounter(yyleng); return PUNCT_OPEN_PAREN; }
")"     { printLexeme(yytext, "PUNCT_CLOSE_PAREN"); incrementColumnCounter(yyleng); return PUNCT_CLOSE_PAREN; }
"{"     { printLexeme(yytext, "PUNCT_OPEN_BRACE"); incrementColumnCounter(yyleng); return PUNCT_OPEN_BRACE; }
"}"     { printLexeme(yytext, "PUNCT_CLOSE_BRACE"); incrementColumnCounter(yyleng); return PUNCT_CLOSE_BRACE; }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Identifiers and Literal Numbers −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

{identifier} { yylval.str = strdup(yytext); insertTable(yytext, "ID", yylineno, column_number); printLexeme(yytext, "ID"); incrementColumnCounter(yyleng); return ID; }

{float} { yylval.num = atof(yytext); printLexeme(yytext, "FLOAT_LITERAL"); incrementColumnCounter(yyleng); return FLOAT_LITERAL; }

{integer} { yylval.num = atoi(yytext); printLexeme(yytext, "INTEGER_LITERAL"); incrementColumnCounter(yyleng); return INTEGER_LITERAL; }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Errors −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

. { printLexeme(yytext, "LEXICAL_ERROR"); incrementColumnCounter(yyleng); }

%%

void printSymbolTable() {
    printf("\n--- TABELA DE SÍMBOLOS ---\n");
    printf("\nPos.  Token         Lexema           Valor\n");
    printf("---------------------------------------------\n");
    for (int i = 0; i < TABLE_SIZE; i++) {
        for (Symbol* s = table[i]; s != NULL; s = s->next) {
            printf("%-5d %-13s %-16s %g\n", s->pos, s->tokenClass, s->lexeme, s->value);
        }
    }
}