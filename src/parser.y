%{
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

int yylex(void);

void yyerror(const char *s);

%}

/* −−−−−−−−−−−−−−−−−−−− Tokens provenientes do analisador léxico −−−−−−−−−−−−−−−−−−−−− */

%token CHAR
%token COMMA
%token FLOAT
%token ID
%token INT
%token SEMI

%token NUMBER

%token DIGIT 

/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Definição de Precedência −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */

%right ASSIGN
%left OR
%left AND
%left EQ NE
%left LT GT LE GE
%left PLUS MINUS
%left MULT DIV
%right NOT
%right UMINUS

%%

program
  : stmt_list
  ;

stmt_list
  : stmt_list stmt
  | /* vazio */
  ;

stmt
  : var_decl
  | assign_stmt
  | if_stmt
  | while_stmt
  | print_stmt
  | read_stmt
  | block
  ;

block
  : '{' stmt_list '}'
  ;

var_decl
  : type id_list SEMI
  ;

id_list
  : id_list COMMA id_decl
  | id_decl
  ;

id_decl
  : ID
  | ID ASSIGN expr
  ;

type        
  : INT
  | FLOAT
  | CHAR
  | BOOLEAN
  ;

assign_stmt
  : expr SEMI
  ;

primary_expr
  : ID
  | literal
  | LPAREN expr RPAREN

literal
  : INTEGER_LITERAL
  | FLOAT_LITERAL
  | CHAR_LITERAL
  | TRUE
  | FALSE

expr
  : ID ASSIGN expr
  
  | expr OR expr
  | expr AND expr

  | expr EQ expr
  | expr NE expr

  | expr LT expr
  | expr GT expr
  | expr LE expr
  | expr GE expr

  | expr PLUS expr
  | expr MINUS expr

  | expr MULT expr
  | expr DIV expr

  | MINUS expr %prec UMINUS
  | NOT expr %prec NOT

  | primary_expr
  ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

extern void printSymbolTable(); // func do lexer pra printar a tabela
extern int symbol_count;

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

    if (symbol_count > 1) {
        printSymbolTable();
    }

    return 0;
}