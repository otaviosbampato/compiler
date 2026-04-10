%option yylineno
%option noyywrap

%{
#include <stdio.h>
#include <stdlib.h>

int yyval;
int column_number = 1;   
%}

ws                      [ \t]+
newline                 [\n]
digit                   [0-9]
letter                  [a-zA-Z]
float                   ([-+])?({digit}+\.{digit}*|\.{digit}+)
integer                 ([-+])?{digit}+
identifier              {letter}(([{letter}{digit}_])*  [{letter}{digit}])?
singleLineComment       \/\/[^\n]*
multilineComment        \/\*([^*]|\*+[^*/])*\*+\/

%%

if      { return(IF);    }
else    { return(ELSE);  }
while   { return(WHILE); }
print   { return(PRINT); }
read    { return(READ);  }

"<="    { yylval = LE; return(RELOP); }
">="    { yylval = GE; return(RELOP); }
"!="    { yylval = NE; return(RELOP); }
"=="    { yylval = EQ; return(RELOP); }
"<"     { yylval = LT; return(RELOP); }
">"     { yylval = GT; return(RELOP); }

"+"     { return(PLUS);  }
"-"     { return(MINUS); }
"**"    { return(POW);   }
"*"     { return(DOT);   }
"/"     { return(DIV);   }

"&&"    { return(AND); }
"||"    { return(OR);  }
"~"     { return(NEG); }

";"     { return(SC);            }
","     { return(COMMA);         }
"("     { return(OPEN_PAR);      }
")"     { return(CLOSE_PAR);     }
"{"     { return(OPEN_BRACKET);  }
"}"     { return(CLOSE_BRACKET); }


{float} { fprintf(yyout,"%d(%d): %s (FLOAT)\n", yylineno,column_number,yytext); column_number+=yyleng; }

{integer} { fprintf(yyout,"%d(%d): %s (INTEGER)\n", yylineno,column_number,yytext); column_number+=yyleng; }

{identifier} { fprintf(yyout,"%d(%d): %s (ID)\n", yylineno,column_number,yytext); column_number+=yyleng;}

{singleLineComment} { }

{multilineComment} { }

{newline} { column_number = 1; }

. { fprintf(yyout,"%d(%d): %s (ERROR)\n", yylineno,column_number,yytext); column_number+=yyleng;}

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