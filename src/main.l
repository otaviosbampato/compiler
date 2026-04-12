%option yylineno
%option noyywrap

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylval;
int column_number = 1;

#define TYPE_INT 1
#define TYPE_FLOAT 2
#define RELOP_LE 1
#define RELOP_GE 2
#define RELOP_NE 3
#define RELOP_EQ 4
#define RELOP_LT 5
#define RELOP_GT 6
#define LOGIC_AND 1
#define LOGIC_OR 2
#define LOGIC_NEG 3
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

/* Estrutura do símbolo */
typedef struct simbolo {
    char *lexeme;           // lexeme string
    char *tokenClass;        // token class (identifier)
    int line;              // lexeme line
    int column;             // lexeme column
    struct simbolo *next;   // para colisões da hash (linked list)
} Symbol;

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
    newSymbol->lexeme = strdup(lexeme);
    newSymbol->tokenClass = strdup(tokenClass);
    newSymbol->line = line;
    newSymbol->column = column;
    newSymbol->next = table[h];
    table[h] = newSymbol;
}

%}

/* Regex Definitions  */

ws                      [ \t]+
newline                 [\n]
digit                   [0-9]
letter                  [a-zA-Z]
float                   ({digit}+\.{digit}*|\.{digit}+)
integer                 {digit}+
identifier              [a-zA-Z]([a-zA-Z0-9_]*[a-zA-Z0-9])? 
singleLineComment       \/\/[^\n]*
multilineComment        \/\*([^*]|\*+[^*/])*\*+\/
invalidSequence         [^a-zA-Z0-9_ \t\n]+
invalidIdentifier       (_+{identifier}|{digit}+{identifier}|{identifier}_+)

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

if      { printLexeme(yytext, "IF"); incrementColumnCounter(yyleng);    }
else    { printLexeme(yytext, "ELSE"); incrementColumnCounter(yyleng);  }
while   { printLexeme(yytext, "WHILE"); incrementColumnCounter(yyleng); }
print   { printLexeme(yytext, "PRINT"); incrementColumnCounter(yyleng); }
read    { printLexeme(yytext, "READ"); incrementColumnCounter(yyleng);  }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Type Definitions −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

int    { yylval = TYPE_INT; printLexeme(yytext, "TYPE (TYPE_INT)"); incrementColumnCounter(yyleng); }
float  { yylval = TYPE_FLOAT; printLexeme(yytext, "TYPE (TYPE_FLOAT)"); incrementColumnCounter(yyleng); }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Relational Operators −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

"<="    { yylval = RELOP_LE; printLexeme(yytext, "RELOP (RELOP_LE)"); incrementColumnCounter(yyleng); }
">="    { yylval = RELOP_GE; printLexeme(yytext, "RELOP (RELOP_GE)"); incrementColumnCounter(yyleng); }
"!="    { yylval = RELOP_NE; printLexeme(yytext, "RELOP (RELOP_NE)"); incrementColumnCounter(yyleng); }
"=="    { yylval = RELOP_EQ; printLexeme(yytext, "RELOP (RELOP_EQ)"); incrementColumnCounter(yyleng); }
"<"     { yylval = RELOP_LT; printLexeme(yytext, "RELOP (RELOP_LT)"); incrementColumnCounter(yyleng); }
">"     { yylval = RELOP_GT; printLexeme(yytext, "RELOP (RELOP_GT)"); incrementColumnCounter(yyleng); }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Assignment Operators −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

"="     { printLexeme(yytext, "ASSIGN_OP"); incrementColumnCounter(yyleng); }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Arithmetic Operators −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

"+"     { printLexeme(yytext, "ARITH_OP_ADD"); incrementColumnCounter(yyleng); }
"-"     { printLexeme(yytext, "ARITH_OP_SUB"); incrementColumnCounter(yyleng); }
"**"    { printLexeme(yytext, "ARITH_OP_POW"); incrementColumnCounter(yyleng); }
"*"     { printLexeme(yytext, "ARITH_OP_MUL"); incrementColumnCounter(yyleng); }
"/"     { printLexeme(yytext, "ARITH_OP_DIV"); incrementColumnCounter(yyleng); }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Logical Operators −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

"&&"    { yylval = LOGIC_AND; printLexeme(yytext, "LOGIC_OP (LOGIC_AND)"); incrementColumnCounter(yyleng); }
"||"    { yylval = LOGIC_OR; printLexeme(yytext, "LOGIC_OP (LOGIC_OR)"); incrementColumnCounter(yyleng);  }
"~"     { yylval = LOGIC_NEG; printLexeme(yytext, "LOGIC_OP (LOGIC_NEG)"); incrementColumnCounter(yyleng); }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Punctuation Symbols −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

";"     { printLexeme(yytext, "PUNCT_SEMICOLON"); incrementColumnCounter(yyleng); }
","     { printLexeme(yytext, "PUNCT_COMMA"); incrementColumnCounter(yyleng); }
"("     { printLexeme(yytext, "PUNCT_OPEN_PAREN"); incrementColumnCounter(yyleng); }
")"     { printLexeme(yytext, "PUNCT_CLOSE_PAREN"); incrementColumnCounter(yyleng); }
"{"     { printLexeme(yytext, "PUNCT_OPEN_BRACE"); incrementColumnCounter(yyleng); }
"}"     { printLexeme(yytext, "PUNCT_CLOSE_BRACE"); incrementColumnCounter(yyleng); }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Identifiers and Numbers −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

{invalidIdentifier} { printLexeme(yytext, "LEXICAL_ERROR"); incrementColumnCounter(yyleng); }

{identifier} { insertTable(yytext, "IDENTIFIER", yylineno, column_number); printLexeme(yytext, "IDENTIFIER"); incrementColumnCounter(yyleng); }

{float} { yylval = NUMBER_FLOAT; printLexeme(yytext, "NUMBER (NUMBER_FLOAT)"); incrementColumnCounter(yyleng); }

{integer} { yylval = NUMBER_INT; printLexeme(yytext, "NUMBER (NUMBER_INT)"); incrementColumnCounter(yyleng); }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Errors −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

{invalidSequence} { printLexeme(yytext, "LEXICAL_ERROR"); incrementColumnCounter(yyleng); }

. { printLexeme(yytext, "LEXICAL_ERROR"); incrementColumnCounter(yyleng); }

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
    printf("\n--- TABELA DE SÍMBOLOS ---\n");
    printf("\nToken         Lexema\n");
    printf("----------------------\n");
    for (int i = 0; i < TABLE_SIZE; i++) {
        for (Symbol* s = table[i]; s != NULL; s = s->next) {
            printf("%-13s %s\n", s->tokenClass, s->lexeme);
        }
    }

    fclose(yyin);
    return 0;
}