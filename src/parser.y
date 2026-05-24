%code requires {
typedef struct simbolo {
    int pos;
    char *lexeme;
    char *tokenClass;
    int line;
    int column;
    double value;
    struct simbolo *next;
} Symbol;
extern Symbol* searchTable(const char* lexeme);
}

%{
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

int yylex(void);

void yyerror(const char *s);

%}

%code {
/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−− Auxiliary Functions −−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−− */

/* Lê o valor de um identificador da tabela de símbolos */
double handle_read_id(const char *id_name) {
    printf("Consultando tabela de simbolos para: %s\n", id_name);
    Symbol *sym = searchTable(id_name);
    if (sym) {
        printf("  Encontrado na posicao %d, valor: %g\n", sym->pos, sym->value);
        return sym->value;
    } else {
        printf("  Nao encontrado!\n");
        return 0.0;
    }
}

/* Atribui um valor a um identificador na tabela de símbolos */
double handle_assign_id(const char *id_name, double value) {
    Symbol *sym = searchTable(id_name);
    if (sym) {
        sym->value = value;
        printf("Atualizado na tabela de simbolos (posicao %d) com valor: %g\n", sym->pos, value);
    } else {
        printf("  Nao encontrado na tabela de simbolos!\n");
    }
    return value;
}
}

%union {
    double num;
    char *str;
}

/* −−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−−− Lexer Tokens −−−−−−−−−−−−−−−−−−−−−−−−−−−−−−− */

%token IF
%token ELSE
%token WHILE
%token PRINT
%token READ

%token <num> TYPE

%token <num> RELOP
%token <num> EQOP
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

%token <str> ID
%token <num> INTEGER_LITERAL
%token <num> FLOAT_LITERAL

%type <num> id_decl assign_stmt primary_expr literal expr

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
  | if_stmt
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
  : ID { printf("Declarando variavel: %s\n", $1); $$ = 0.0; }
  | ID ASSIGN expr { 
      printf("Atribuindo valor na declaracao de: %s\n", $1);
      $$ = handle_assign_id($1, $3);
  }
  ;

assign_stmt
  : expr PUNCT_SEMICOLON { printf("Resultado da expressao: %g\n", $1); }
  ;

if_stmt
  : IF PUNCT_OPEN_PAREN expr PUNCT_CLOSE_PAREN block else_clause
  ;

else_clause
  : /* vazio */
  | ELSE block
  | ELSE if_stmt
  ;

primary_expr
  : ID { $$ = handle_read_id($1); }
  | literal
  | PUNCT_OPEN_PAREN expr PUNCT_CLOSE_PAREN { $$ = $2; }
  ;

literal
  : INTEGER_LITERAL
  | FLOAT_LITERAL
  ;

expr
  : ID ASSIGN expr { 
      printf("Assigning to %s: %g\n", $1, $3);
      $$ = handle_assign_id($1, $3);
  }
  
  | expr OR expr { $$ = $1 || $3; }
  | expr AND expr { $$ = $1 && $3; }

  | expr EQOP expr { $$ = $1 == $3; }
  | expr RELOP expr { 
      switch((int)$2) {
          case 1: $$ = $1 <= $3; break;  /* RELOP_LE */
          case 2: $$ = $1 >= $3; break;  /* RELOP_GE */
          case 3: $$ = $1 < $3; break;   /* RELOP_LT */
          case 4: $$ = $1 > $3; break;   /* RELOP_GT */
          default: $$ = 0;
      }
  }

  | expr PLUS expr { $$ = $1 + $3; }
  | expr MINUS expr { $$ = $1 - $3; }

  | expr MULT expr { $$ = $1 * $3; }
  | expr DIV expr { $$ = $1 / $3; }

  | MINUS expr %prec UMINUS { $$ = -$2; }
  | NOT expr %prec NOT { $$ = !$2; }

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