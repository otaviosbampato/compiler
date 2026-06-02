%{
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

int yylex(void);

void yyerror(const char *s);

%}

/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−− Lexer Tokens −−−−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%define parse.error verbose

%token IF
%token ELSE
%token WHILE
%token PRINT
%token READ
%token RETURN

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
%token STR_LITERAL
%token BOOL_LITERAL

/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−− Definição de Precedência −−−−−−−−−−−−−−−−−−−−−−−−−−−−− */

%precedence ASSIGN
%left OR
%left AND
%left EQOP
%left RELOP
%left PLUS MINUS
%left MULT DIV
%right POW
%precedence NOT
%precedence UMINUS

%%

program
  : global_decl_list
  ;

global_decl_list
  : global_decl_list global_decl
  | %empty /* vazio */
  ;

global_decl
  : func_decl
  | var_decl
  ;

func_decl
  : TYPE ID PUNCT_OPEN_PAREN opt_param_list PUNCT_CLOSE_PAREN block
  ;

opt_param_list
  : param_list
  | %empty /* vazio */
  ;

param_list
  : param_list PUNCT_COMMA TYPE ID
  | TYPE ID
  ;

func_call
  : ID PUNCT_OPEN_PAREN opt_func_call_list PUNCT_CLOSE_PAREN
  ;

opt_func_call_list
  : func_call_list
  | %empty /* vazio */
  ;

func_call_list
  : func_call_list PUNCT_COMMA expr
  | expr
  ;

stmt_list
  : stmt_list stmt
  | %empty /* vazio */
  ;

stmt
  : var_decl
  | assign_stmt
  | if_stmt
  | while_stmt
  | print_stmt
  | read_stmt
  | return_stmt
  | block
  ;

return_stmt
  : RETURN opt_expr PUNCT_SEMICOLON
  ;

opt_expr
  : expr
  | %empty /* vazio */
  ;

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

if_stmt
  : IF PUNCT_OPEN_PAREN expr PUNCT_CLOSE_PAREN block else_clause
  ;

else_clause
  : %empty /* vazio */
  | ELSE block
  | ELSE if_stmt
  ;

while_stmt
  : WHILE PUNCT_OPEN_PAREN expr PUNCT_CLOSE_PAREN block
  ;

print_stmt
  : PRINT PUNCT_OPEN_PAREN print_list PUNCT_CLOSE_PAREN PUNCT_SEMICOLON
  ;

print_list
  : print_list PUNCT_COMMA expr
  | expr
  ;

read_stmt
  : READ PUNCT_OPEN_PAREN read_list PUNCT_CLOSE_PAREN PUNCT_SEMICOLON
  ;

read_list
  : read_list PUNCT_COMMA ID
  | ID
  ;

primary_expr
  : ID
  | literal
  | PUNCT_OPEN_PAREN expr PUNCT_CLOSE_PAREN
  | func_call
  ;

literal
  : INTEGER_LITERAL
  | FLOAT_LITERAL
  | STR_LITERAL
  | BOOL_LITERAL
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
  | expr POW expr

  | MINUS expr %prec UMINUS 
  | NOT expr %prec NOT 

  | primary_expr
  ;

%%

void yyerror(const char *s) {
    extern int yylineno;
    extern int column_number;
    extern int yyleng;
    fprintf(stderr, "Error at line %d, column %d: %s\n", yylineno, column_number - yyleng, s);
}

extern void printSymbolTable(); // func do lexer pra printar a tabela
extern int symbol_count;
extern int lexical_error_count;

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
    int has_errors = (yyparse() != 0) || (lexical_error_count > 0);

    if (!has_errors) {
      printf("Aceita\n");
    }

    if (symbol_count > 1) {
      printSymbolTable();
    }

    return has_errors ? 1 : 0;
}
