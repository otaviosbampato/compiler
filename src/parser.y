%{
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

int yylex(void);

void yyerror(const char *s);

%}

%define api.value.type {double} /*Para indicar que lidaremos com double*/

/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−− Lexer Tokens −−−−−−−−−−−−−−−−−−−−−−−−−−−−−−− */

%token IF
%token ELSE
%token WHILE
%token PRINT
%token READ

%token TYPE

%token RELOP
%token EQOP
%token AND
%token OR
%token NOT

%token ASSIGN

%token PLUS
%token MINUS
%token POW
%token MULT
%token DIV

%token PUNCT_SEMICOLON
%token PUNCT_COMMA
%token PUNCT_OPEN_PAREN
%token PUNCT_CLOSE_PAREN
%token PUNCT_OPEN_BRACE
%token PUNCT_CLOSE_BRACE

%token ID
%token INTEGER_LITERAL
%token FLOAT_LITERAL

/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Definição de Precedência −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */

%right ASSIGN
%left OR
%left AND
%left EQOP
%left RELOP
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
  | block
  ;

  /*
    stmt
    : var_decl
    | assign_stmt
    | if_stmt
    | while_stmt
    | print_stmt
    | read_stmt
    | block
    ;
  */

block
  : PUNCT_OPEN_BRACE stmt_list PUNCT_CLOSE_BRACE
  ;

var_decl
  : TYPE id_list PUNCT_SEMICOLON
  ;

id_list
  : id_list PUNCT_COMMA id_decl
  | id_decl
  ;

id_decl
  : ID
  | ID ASSIGN expr
  ;

assign_stmt
  : expr PUNCT_SEMICOLON
  ;

primary_expr
  : ID
  | literal
  | PUNCT_OPEN_PAREN expr PUNCT_CLOSE_PAREN

literal
  : INTEGER_LITERAL
  | FLOAT_LITERAL
  ;

expr
  : ID ASSIGN expr
  
  | expr OR expr
  | expr AND expr

  | expr EQOP expr
  | expr RELOP expr

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