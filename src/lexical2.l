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

%}

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

{ws} { incrementColumnCounter(yyleng); }

{newline} { resetColumnCounter(); }

{singleLineComment} { printLexema(yytext, "Single Line Comment"); incrementColumnCounter(yyleng); }

{multilineComment} { printLexema(yytext, "Multi Line Comment"); incrementColumnCounter(yyleng); }

if      { printLexema(yytext, "IF"); incrementColumnCounter(yyleng); }
else    { printLexema(yytext, "ELSE"); incrementColumnCounter(yyleng); }
while   { printLexema(yytext, "WHILE"); incrementColumnCounter(yyleng); }
print   { printLexema(yytext, "PRINT"); incrementColumnCounter(yyleng); }
read    { printLexema(yytext, "READ"); incrementColumnCounter(yyleng); }

{identifier} { printLexema(yytext, "ID"); incrementColumnCounter(yyleng); }

{float} { printLexema(yytext, "FLOAT"); incrementColumnCounter(yyleng); }

{integer} { printLexema(yytext, "INTEGER"); incrementColumnCounter(yyleng); }

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