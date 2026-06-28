%{
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include "symtable.h"

int yylex(void);
/* variável para carregar o tipo corrente durante declarações */
static int current_decl_type = 0;

void yyerror(const char *s);

%}

// !!
// !! REMOVER TIPOS BOOLEAN E STRING (TIROU PONTO DA ÚLTIMA)
// !!

%union {
    int   ival;   /* valor inteiro: TYPE_INT, RELOP_LE, etc. */
    char *sval;       /* lexema de um identificador              */
    struct {
        int tipo; /* tipo semântico do resultado (SYM_TYPE_*)*/
        char* code // codigo de fato da expr  
    } expr;
}

// * definimos os valores de %union usados por essas expressões
%type <expr> expr primary_expr literal

/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−− Lexer Tokens −−−−−−−−−−−−−−−−−−−−−−−−−−−−−−− */
%define parse.error verbose

%token IF
%token ELSE
%token WHILE
%token PRINT
%token READ
%token RETURN

%token <ival> TYPE

%token <ival> RELOP
%token <ival> EQOP
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

%token <sval> ID
%token <sval> STR_LITERAL
%token <ival> BOOL_LITERAL
%token INTEGER_LITERAL
%token FLOAT_LITERAL

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
  : TYPE    
    ID PUNCT_OPEN_PAREN 
    {
      // atualiza o tipo
      current_decl_type = $1.ival;
      // * registra a função no escopo global antes de abrir o escopo dela
      // ? onde a gente atualiza current_decl_type? oq isso significa?
      sym_declare($2.sval, current_decl_type, SYM_FUNC,
                  yylineno, column_number);
      open_scope();   // * escopo dos parâmetros + corpo
    } opt_param_list PUNCT_CLOSE_PAREN block {close_scope();}
  ;

opt_param_list
  : param_list
  | %empty /* vazio */
  ;

param_list
  : param_list PUNCT_COMMA TYPE ID { sym_declare($4.sval, current_decl_type, SYM_PARAM, yylineno, column_number); }
  | TYPE ID { sym_declare($2.sval, current_decl_type, SYM_PARAM, yylineno, column_number); }
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
  : PUNCT_OPEN_BRACE {open_scope();} stmt_list PUNCT_CLOSE_BRACE {close_scope();}
  ;

var_decl
  : TYPE {current_decl_type = $1.ival;} id_list PUNCT_SEMICOLON
  ;

id_list
  : id_list PUNCT_COMMA id_decl
  | id_decl
  ;

id_decl
  : ID {sym_declare($1.sval, current_decl_type, SYM_VAR, yylineno, column_number);}
  | ID ASSIGN expr 
    {Symbol *s = sym_declare($1.sval, current_decl_type, SYM_VAR, yylineno, column_number);
      int compativel =
                (s->type == $3.expr.tipo) ||
                (s->type == SYM_TYPE_INT   && $3.expr.tipo == SYM_TYPE_FLOAT) ||
                (s->type == SYM_TYPE_FLOAT && $3.expr.tipo == SYM_TYPE_INT);
      if(!compativel){
          fprintf(stderr,
                "Erro semântico linha %d: tipo incompatível na inicialização de '%s' "
                "(esperado '%s', recebeu '%s')\n",
                yylineno, s->name,
                sym_type_str(s->type), sym_type_str($3.expr.tipo));
        }
      }
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
    {
      Symbol *s = sym_lookup($1.sval);
      if (!s) {
          fprintf(stderr, "Erro semântico linha %d: '%s' não declarado\n",
                  yylineno, $1.sval);
          $$.tipo = SYM_TYPE_INT;  //* tipo de recuperação para não propagar erro
      } else {
          $$.tipo = s->type;
      }
    }
  | literal
  | PUNCT_OPEN_PAREN expr PUNCT_CLOSE_PAREN
  | func_call
  ;

literal
  : INTEGER_LITERAL { $$.tipo = SYM_TYPE_INT;   }
  | FLOAT_LITERAL   { $$.tipo = SYM_TYPE_FLOAT; }
  | STR_LITERAL     { $$.tipo = SYM_TYPE_STR;   }
  | BOOL_LITERAL    { $$.tipo = SYM_TYPE_BOOL;  }
  ;

expr
  : ID ASSIGN expr
    {
        Symbol *s = sym_lookup($1.sval);
        if (!s) {
            fprintf(stderr, "Erro semântico linha %d: '%s' não declarado\n",
                    yylineno, $1.sval);
            $$.tipo = SYM_TYPE_INT;
        } else {
            // * verificação de tipo
            int compativel =
                (s->type == $3.expr.tipo) ||
                (s->type == SYM_TYPE_INT && $3.expr.tipo == SYM_TYPE_FLOAT) ||
                (s->type == SYM_TYPE_FLOAT && $3.expr.tipo == SYM_TYPE_INT);
            if (!compativel) {
                fprintf(stderr,
                "Erro semântico linha %d: tipo incompatível na atribuição de '%s' "
                "(esperado '%s', recebeu '%s')\n",
                yylineno, s->name,
                sym_type_str(s->type), sym_type_str($3.expr.tipo));
            }
            $$.tipo = s->type;
        }
    }
  
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

extern int lexical_error_count;

int main(int argc, char **argv) {
  sym_init();
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

  sym_print();

  return has_errors ? 1 : 0;
}
