%option yylineno
%option noyywrap

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.h"

// yylval é sendo importado pelo parser agora.
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

int lexical_error_count = 0;

static char *copy_lexeme(const char *text) {
    char *copy = malloc(strlen(text) + 1);

    if (!copy) {
        perror("malloc");
        exit(1);
    }

    strcpy(copy, text);
    return copy;
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
return  { printLexeme(yytext, "RETURN"); incrementColumnCounter(yyleng); return RETURN; }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Type Definitions −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

int     { yylval.ival = TYPE_INT; printLexeme(yytext, "TYPE (TYPE_INT)"); incrementColumnCounter(yyleng); return TYPE; }
float   { yylval.ival = TYPE_FLOAT; printLexeme(yytext, "TYPE (TYPE_FLOAT)"); incrementColumnCounter(yyleng); return TYPE; }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Relational Operators −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

"<="    { yylval.ival = RELOP_LE; printLexeme(yytext, "RELOP (RELOP_LE)"); incrementColumnCounter(yyleng); return RELOP; }
">="    { yylval.ival = RELOP_GE; printLexeme(yytext, "RELOP (RELOP_GE)"); incrementColumnCounter(yyleng); return RELOP; }
"!="    { yylval.ival = EQOP_NE; printLexeme(yytext, "EQOP (EQOP_NE)"); incrementColumnCounter(yyleng); return EQOP; }
"=="    { yylval.ival = EQOP_EQ; printLexeme(yytext, "EQOP (EQOP_EQ)"); incrementColumnCounter(yyleng); return EQOP; }
"<"     { yylval.ival = RELOP_LT; printLexeme(yytext, "RELOP (RELOP_LT)"); incrementColumnCounter(yyleng); return RELOP; }
">"     { yylval.ival = RELOP_GT; printLexeme(yytext, "RELOP (RELOP_GT)"); incrementColumnCounter(yyleng); return RELOP; }

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

{identifier} { yylval.sval = copy_lexeme(yytext); printLexeme(yytext, "ID"); incrementColumnCounter(yyleng); return ID; }

{float}   { yylval.sval = copy_lexeme(yytext); printLexeme(yytext, "FLOAT_LITERAL"); incrementColumnCounter(yyleng); return FLOAT_LITERAL; }

{integer} { yylval.sval = copy_lexeme(yytext); printLexeme(yytext, "INTEGER_LITERAL"); incrementColumnCounter(yyleng); return INTEGER_LITERAL; }

%{
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Errors −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%}

. {
    lexical_error_count++;
    printLexeme(yytext, "LEXICAL_ERROR");
    incrementColumnCounter(yyleng);
}

%%