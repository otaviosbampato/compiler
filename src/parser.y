%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "symtable.h"
#include "temporary.h"
#include "tac-generator.h"
#include "utils.h"

int yylex(void);

extern int column_number;
extern int lexical_error_count;
extern int yylineno;

static int current_decl_type = 0;
static int label_counter = 0;
int semantic_error_count = 0;

#define EQOP_NE 1
#define EQOP_EQ 2
#define RELOP_LE 1
#define RELOP_GE 2
#define RELOP_LT 3
#define RELOP_GT 4

void yyerror(const char *s);
int tipos_compativeis(int, int);
static char *dup_text(const char *text);
static char *join2(const char *left, const char *right);
static char *join3(const char *first, const char *second, const char *third);
static char *new_temp_name(void);
static char *new_label_name(void);
static int is_numeric_type(int type);
static char *relop_text(int op);
static char *eqop_text(int op);
static int has_text(const char *text);

%}

%union {
    int ival;
    char *sval;
    struct {
        int tipo;
        char *place;
        char *code;
    } expr;
    struct {
        char *code;
    } stmt;
    struct {
        char *code;
        int count;
    } args;
    struct {
        int tipo;
        char *name;
        int category;
    } use_id;
}

%type <stmt> program global_decl_list global_decl func_decl func_scope set_type stmt_list stmt block no_scope_block
%type <stmt> var_decl id_list id_decl opt_param_list param_list param_item print_stmt read_stmt return_stmt else_clause if_stmt while_stmt
%type <expr> opt_expr
%type <expr> expr primary_expr literal func_call
%type <args> opt_func_call_list func_call_list print_list read_list
%type <use_id> use_id use_func_id use_var_id decl_var_id decl_func_id decl_param_id

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
%token <sval> INTEGER_LITERAL
%token <sval> FLOAT_LITERAL

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
  : { sym_init(); } global_decl_list
    {
      output_code($2.code);
      $$.code = $2.code;
    }
  ;

global_decl_list
  : global_decl_list global_decl
    {
      $$.code = join2($1.code, $2.code);
    }
  | %empty
    {
      $$.code = dup_text("");
    }
  ;

global_decl
  : func_decl
    {
      $$.code = $1.code;
    }
  | var_decl
    {
      $$.code = $1.code;
    }
  ;

func_decl
  : set_type decl_func_id PUNCT_OPEN_PAREN func_scope opt_param_list PUNCT_CLOSE_PAREN no_scope_block
    {
      char *label = generate_label($2.name);
      char *body = join2(label, $7.code);
      $$.code = body;
      close_scope();
    }
  ;

set_type
  : TYPE
    {
      current_decl_type = $1;
      $$.code = dup_text("");
    }
  ;

func_scope
  : %empty
    {
      open_scope();
      $$.code = dup_text("");
    }
  ;

opt_param_list
  : param_list
    {
      $$.code = $1.code;
    }
  | %empty
    {
      $$.code = dup_text("");
    }
  ;

param_list
  : param_list PUNCT_COMMA param_item
    {
      $$.code = join2($1.code, $3.code);
    }
  | param_item
    {
      $$.code = $1.code;
    }
  ;

param_item
  : TYPE
    {
      current_decl_type = $1;
    }
    decl_param_id
    {
      $$.code = dup_text("");
    }
  ;

stmt_list
  : stmt_list stmt
    {
      $$.code = join2($1.code, $2.code);
    }
  | %empty
    {
      $$.code = dup_text("");
    }
  ;

stmt
  : var_decl
    {
      $$.code = $1.code;
    }
  | expr PUNCT_SEMICOLON
    {
      $$.code = $1.code;
    }
  | if_stmt
    {
      $$.code = $1.code;
    }
  | while_stmt
    {
      $$.code = $1.code;
    }
  | print_stmt
    {
      $$.code = $1.code;
    }
  | read_stmt
    {
      $$.code = $1.code;
    }
  | return_stmt
    {
      $$.code = $1.code;
    }
  | block
    {
      $$.code = $1.code;
    }
  ;

block
  : PUNCT_OPEN_BRACE
    {
      open_scope();
    }
    stmt_list PUNCT_CLOSE_BRACE
    {
      close_scope();
      $$.code = $3.code;
    }
  ;

no_scope_block
  : PUNCT_OPEN_BRACE stmt_list PUNCT_CLOSE_BRACE
    {
      $$.code = $2.code;
    }
  ;

var_decl
  : set_type id_list PUNCT_SEMICOLON
    {
      $$.code = $2.code;
    }
  ;

id_list
  : id_list PUNCT_COMMA id_decl
    {
      $$.code = join2($1.code, $3.code);
    }
  | id_decl
    {
      $$.code = $1.code;
    }
  ;

id_decl
  : decl_var_id
    {
      $$.code = dup_text("");
    }
  | decl_var_id ASSIGN expr
    {
      if (!tipos_compativeis($1.tipo, $3.tipo)) {
        fprintf(stderr,
                "Erro semântico linha %d: tipo incompatível na inicialização de '%s' "
                "(esperado '%s', recebeu '%s')\n",
                yylineno, $1.name,
                sym_type_str($1.tipo), sym_type_str($3.tipo));
        semantic_error_count++;
      }

      $$.code = join2($3.code, generate("=", $3.place, NULL, $1.name));
    }
  ;

return_stmt
  : RETURN opt_expr PUNCT_SEMICOLON
    {
      $$.code = join2($2.code, generate_return($2.place));
    }
  ;

opt_expr
  : expr
    {
      $$.code = $1.code;
      $$.tipo = $1.tipo;
      $$.place = $1.place;
    }
  | %empty
    {
      $$.code = dup_text("");
      $$.tipo = 0;
      $$.place = dup_text("");
    }
  ;

if_stmt
  : IF PUNCT_OPEN_PAREN expr PUNCT_CLOSE_PAREN block else_clause
    {
      if (!is_numeric_type($3.tipo)) {
        fprintf(stderr,
                "Erro semântico linha %d: condição do if deve ser numérica\n",
                yylineno);
        semantic_error_count++;
      }

      char *Ltrue = new_label_name();
      char *Lfalse = new_label_name();
      char *Lend = new_label_name();
      char *code = NULL;

      code = join2($3.code, generate_if_goto($3.place, Ltrue));
      code = join2(code, generate_goto(has_text($6.code) ? Lfalse : Lend));
      code = join2(code, generate_label(Ltrue));
      code = join2(code, $5.code);

      if (has_text($6.code)) {
        code = join2(code, generate_goto(Lend));
        code = join2(code, generate_label(Lfalse));
        code = join2(code, $6.code);
      }

      code = join2(code, generate_label(Lend));
      $$.code = code;
    }
  ;

else_clause
  : %empty
    {
      $$.code = dup_text("");
    }
  | ELSE block
    {
      $$.code = $2.code;
    }
  | ELSE if_stmt
    {
      $$.code = $2.code;
    }
  ;

while_stmt
  : WHILE PUNCT_OPEN_PAREN expr PUNCT_CLOSE_PAREN block
    {
      if (!is_numeric_type($3.tipo)) {
        fprintf(stderr,
                "Erro semântico linha %d: condição do while deve ser numérica\n",
                yylineno);
        semantic_error_count++;
      }

      char *Lbegin = new_label_name();
      char *Lbody = new_label_name();
      char *Lend = new_label_name();
      char *code = NULL;

      code = join2(generate_label(Lbegin), $3.code);
      code = join2(code, generate_if_goto($3.place, Lbody));
      code = join2(code, generate_goto(Lend));
      code = join2(code, generate_label(Lbody));
      code = join2(code, $5.code);
      code = join2(code, generate_goto(Lbegin));
      code = join2(code, generate_label(Lend));
      $$.code = code;
    }
  ;

print_stmt
  : PRINT PUNCT_OPEN_PAREN print_list PUNCT_CLOSE_PAREN PUNCT_SEMICOLON
    {
      $$.code = $3.code;
    }
  ;

print_list
  : print_list PUNCT_COMMA expr
    {
      $$.code = join3($1.code, $3.code, generate_print($3.place));
      $$.count = $1.count + 1;
    }
  | expr
    {
      $$.code = join2($1.code, generate_print($1.place));
      $$.count = 1;
    }
  ;

read_stmt
  : READ PUNCT_OPEN_PAREN read_list PUNCT_CLOSE_PAREN PUNCT_SEMICOLON
    {
      $$.code = $3.code;
    }
  ;

read_list
  : read_list PUNCT_COMMA use_var_id
    {
      $$.code = join2($1.code, generate_read($3.name));
      $$.count = $1.count + 1;
    }
  | use_var_id
    {
      $$.code = generate_read($1.name);
      $$.count = 1;
    }
  ;

expr
  : use_var_id ASSIGN expr
    {
      if (!tipos_compativeis($1.tipo, $3.tipo)) {
        fprintf(stderr,
                "Erro semântico linha %d: tipo incompatível na atribuição de '%s' "
                "(esperado '%s', recebeu '%s')\n",
                yylineno, $1.name,
                sym_type_str($1.tipo), sym_type_str($3.tipo));
        semantic_error_count++;
      }

      $$.tipo = $1.tipo;
      $$.place = $1.name;
      $$.code = join2($3.code, generate("=", $3.place, NULL, $1.name));
    }
  | expr OR expr
    {
      $$.tipo = SYM_TYPE_INT;
      $$.place = new_temp_name();
      $$.code = join3($1.code, $3.code, generate("||", $1.place, $3.place, $$.place));
    }
  | expr AND expr
    {
      $$.tipo = SYM_TYPE_INT;
      $$.place = new_temp_name();
      $$.code = join3($1.code, $3.code, generate("&&", $1.place, $3.place, $$.place));
    }
  | expr EQOP expr
    {
      $$.tipo = SYM_TYPE_INT;
      $$.place = new_temp_name();
      $$.code = join3($1.code, $3.code, generate(eqop_text($2), $1.place, $3.place, $$.place));
    }
  | expr RELOP expr
    {
      $$.tipo = SYM_TYPE_INT;
      $$.place = new_temp_name();
      $$.code = join3($1.code, $3.code, generate(relop_text($2), $1.place, $3.place, $$.place));
    }
  | expr PLUS expr
    {
      $$.tipo = max($1.tipo, $3.tipo);
      $$.place = new_temp_name();
      $$.code = join3($1.code, $3.code, generate("+", $1.place, $3.place, $$.place));
    }
  | expr MINUS expr
    {
      $$.tipo = max($1.tipo, $3.tipo);
      $$.place = new_temp_name();
      $$.code = join3($1.code, $3.code, generate("-", $1.place, $3.place, $$.place));
    }
  | expr MULT expr
    {
      $$.tipo = max($1.tipo, $3.tipo);
      $$.place = new_temp_name();
      $$.code = join3($1.code, $3.code, generate("*", $1.place, $3.place, $$.place));
    }
  | expr DIV expr
    {
      $$.tipo = max($1.tipo, $3.tipo);
      $$.place = new_temp_name();
      $$.code = join3($1.code, $3.code, generate("/", $1.place, $3.place, $$.place));
    }
  | expr POW expr
    {
      $$.tipo = max($1.tipo, $3.tipo);
      $$.place = new_temp_name();
      $$.code = join3($1.code, $3.code, generate("**", $1.place, $3.place, $$.place));
    }
  | MINUS expr %prec UMINUS
    {
      $$.tipo = $2.tipo;
      $$.place = new_temp_name();
      $$.code = join2($2.code, generate("-", $2.place, NULL, $$.place));
    }
  | NOT expr %prec NOT
    {
      $$.tipo = SYM_TYPE_INT;
      $$.place = new_temp_name();
      $$.code = join2($2.code, generate("~", $2.place, NULL, $$.place));
    }
  | primary_expr
    {
      $$.tipo = $1.tipo;
      $$.place = $1.place;
      $$.code = $1.code;
    }
  ;

primary_expr
  : use_var_id
    {
      $$.tipo = $1.tipo;
      $$.place = $1.name;
      $$.code = dup_text("");
    }
  | literal
    {
      $$.tipo = $1.tipo;
      $$.place = $1.place;
      $$.code = dup_text("");
    }
  | PUNCT_OPEN_PAREN expr PUNCT_CLOSE_PAREN
    {
      $$.tipo = $2.tipo;
      $$.place = $2.place;
      $$.code = $2.code;
    }
  | func_call
    {
      $$.tipo = $1.tipo;
      $$.place = $1.place;
      $$.code = $1.code;
    }
  ;

literal
  : INTEGER_LITERAL
    {
      $$.tipo = SYM_TYPE_INT;
      $$.place = $1;
      $$.code = dup_text("");
    }
  | FLOAT_LITERAL
    {
      $$.tipo = SYM_TYPE_FLOAT;
      $$.place = $1;
      $$.code = dup_text("");
    }
  ;

func_call
  : use_func_id PUNCT_OPEN_PAREN opt_func_call_list PUNCT_CLOSE_PAREN
    {
      char *temp_name = new_temp_name();
      char *call_line = generate_call_assign(temp_name, $1.name, $3.count);
      $$.tipo = $1.tipo;
      $$.place = temp_name;
      $$.code = join2($3.code, call_line);
    }
  ;

opt_func_call_list
  : func_call_list
    {
      $$.code = $1.code;
      $$.count = $1.count;
    }
  | %empty
    {
      $$.code = dup_text("");
      $$.count = 0;
    }
  ;

func_call_list
  : func_call_list PUNCT_COMMA expr
    {
      $$.code = join3($1.code, $3.code, generate_param($3.place));
      $$.count = $1.count + 1;
    }
  | expr
    {
      $$.code = join2($1.code, generate_param($1.place));
      $$.count = 1;
    }
  ;

use_id
  : ID
    {
      Symbol *symbol = sym_lookup($1);

      if (!symbol) {
        fprintf(stderr, "Erro semântico linha %d: '%s' não declarado\n",
                yylineno, $1);
        semantic_error_count++;
        $$.tipo = SYM_TYPE_INT;
        $$.name = $1;
        $$.category = -1;
      } else {
        $$.tipo = symbol->type;
        $$.name = symbol->name;
        $$.category = symbol->category;
      }
    }
  ;

use_func_id
  : use_id
    {
      if ($1.category != SYM_FUNC) {
        fprintf(stderr, "Erro semântico linha %d: '%s' não é uma função\n",
                yylineno, $1.name);
        semantic_error_count++;
      }

      $$ = $1;
    }
  ;

use_var_id
  : use_id
    {
      if ($1.category != SYM_VAR && $1.category != SYM_PARAM) {
        fprintf(stderr, "Erro semântico linha %d: '%s' não é uma variável\n",
                yylineno, $1.name);
        semantic_error_count++;
      }

      $$ = $1;
    }
  ;

decl_var_id
  : ID
    {
      Symbol *symbol = sym_declare($1, current_decl_type, SYM_VAR, yylineno, column_number);

      if (!symbol) {
        $$.tipo = SYM_TYPE_INT;
        $$.name = $1;
        $$.category = SYM_VAR;
      } else {
        $$.tipo = symbol->type;
        $$.name = symbol->name;
        $$.category = symbol->category;
      }
    }
  ;

decl_func_id
  : ID
    {
      Symbol *symbol = sym_declare($1, current_decl_type, SYM_FUNC, yylineno, column_number);

      if (!symbol) {
        $$.tipo = SYM_TYPE_INT;
        $$.name = $1;
        $$.category = SYM_FUNC;
      } else {
        $$.tipo = symbol->type;
        $$.name = symbol->name;
        $$.category = symbol->category;
      }
    }
  ;

decl_param_id
  : ID
    {
      Symbol *symbol = sym_declare($1, current_decl_type, SYM_PARAM, yylineno, column_number);

      if (!symbol) {
        $$.tipo = SYM_TYPE_INT;
        $$.name = $1;
        $$.category = SYM_PARAM;
      } else {
        $$.tipo = symbol->type;
        $$.name = symbol->name;
        $$.category = symbol->category;
      }
    }
  ;

%%

int tipos_compativeis(int tipo_esperado, int tipo_recebido) {
    return tipo_esperado == tipo_recebido ||
           (tipo_esperado == SYM_TYPE_INT && tipo_recebido == SYM_TYPE_FLOAT) ||
           (tipo_esperado == SYM_TYPE_FLOAT && tipo_recebido == SYM_TYPE_INT);
}

void yyerror(const char *s) {
    extern int yylineno;
    extern int yyleng;

    fprintf(stderr, "Error at line %d, column %d: %s\n",
            yylineno, column_number - yyleng, s);
}

static char *dup_text(const char *text) {
    size_t length = strlen(text) + 1;
    char *copy = (char *)malloc(length);

    if (!copy) {
        perror("malloc");
        exit(1);
    }

    memcpy(copy, text, length);
    return copy;
}

static char *join2(const char *left, const char *right) {
    size_t left_len = left ? strlen(left) : 0;
    size_t right_len = right ? strlen(right) : 0;
    char *result = (char *)malloc(left_len + right_len + 1);

    if (!result) {
        perror("malloc");
        exit(1);
    }

    if (left_len > 0) {
        memcpy(result, left, left_len);
    }

    if (right_len > 0) {
        memcpy(result + left_len, right, right_len);
    }

    result[left_len + right_len] = '\0';
    return result;
}

static char *join3(const char *first, const char *second, const char *third) {
    char *result = join2(first, second);
    char *joined = join2(result, third);
    free(result);
    return joined;
}

static char *new_temp_name(void) {
    Temporary *temporary = temporary_new();
    char *name = dup_text(temporary_get_name(temporary));
    temporary_free(temporary);
    return name;
}

static char *new_label_name(void) {
    char buffer[32];
    snprintf(buffer, sizeof(buffer), "L%d", label_counter++);
    return dup_text(buffer);
}

static int is_numeric_type(int type) {
    return type == SYM_TYPE_INT || type == SYM_TYPE_FLOAT;
}

static char *relop_text(int op) {
    switch (op) {
        case RELOP_LE:
            return "<=";
        case RELOP_GE:
            return ">=";
        case RELOP_LT:
            return "<";
        case RELOP_GT:
            return ">";
        default:
            return "";
    }
}

static char *eqop_text(int op) {
    switch (op) {
        case EQOP_NE:
            return "!=";
        case EQOP_EQ:
            return "==";
        default:
            return "";
    }
}

static int has_text(const char *text) {
    return text && text[0] != '\0';
}

int main(int argc, char **argv) {
    extern FILE *yyin;

    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            perror("Error opening file");
            return 1;
        }
    }

    int has_errors = (yyparse() != 0) || (lexical_error_count > 0) || (semantic_error_count > 0);

    if (!has_errors) {
        printf("Aceita\n");
    }

    sym_print();
    return has_errors ? 1 : 0;
}