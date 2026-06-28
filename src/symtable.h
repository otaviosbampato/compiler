#ifndef SYMTABLE_H
#define SYMTABLE_H

/* -----------------------------------------------------------------------
 * symtable.h — Tabela de símbolos com escopos aninhados
 *
 * Modelo: pilha de escopos (lista encadeada de Scope).
 * Cada Scope possui uma lista encadeada de Symbol (hash não é necessária
 * aqui porque o número de símbolos por escopo tende a ser pequeno e a
 * busca linear é simples de implementar e depurar).
 *
 * Abertura de escopo : open_scope()   — chamada em toda regra `block`
 * Fechamento         : close_scope()  — chamada ao fechar o `block`
 * Declaração         : sym_declare()  — chamada em var_decl / func_decl
 * Busca              : sym_lookup()   — chamada em toda referência a ID
 * ----------------------------------------------------------------------- */


// Tipos suportados pela linguagem (espelham os #define do lexer.l)
#define SYM_TYPE_INT    1
#define SYM_TYPE_FLOAT  2
#define SYM_TYPE_BOOL   3
#define SYM_TYPE_VOID   4   /* para funções sem retorno */

// Categorias de símbolo
#define SYM_VAR   0   /* variável local ou global */
#define SYM_FUNC  1   /* função */
#define SYM_PARAM 2   /* parâmetro formal */

// Type Widths (Bytes)
#define INT_WIDTH    4
#define FLOAT_WIDTH  8

// * listinha encadeada
typedef struct Symbol {
    char        *name;          /* lexema do identificador          */
    int          type;          /* SYM_TYPE_*                       */
    int          category;      /* SYM_VAR | SYM_FUNC | SYM_PARAM  */
    int          scope_level;   /* nível de aninhamento (0 = global)*/
    int          line;          /* linha da declaração              */
    int          column;        /* coluna da declaração             */
    struct Symbol *next;        /* próximo símbolo no mesmo escopo  */
} Symbol;

typedef struct Scope {
    Symbol      *symbols;   /* lista de símbolos deste escopo   */
    struct Scope *parent;   /* escopo que o contém              */
    int          level;     /* nível deste escopo               */
} Scope;

// escopo corrente (topo da pilha)
extern Scope *current_scope;

/* Inicializa a pilha com o escopo global (nível 0). Chamar uma vez no main. */
void sym_init(void);

/* Empurra um novo escopo na pilha. Chamar ao abrir '{'. */
void open_scope(void);

/* Desempilha o escopo corrente e libera seus símbolos. Chamar ao fechar '}'. */
void close_scope(void);

/* Declara um símbolo no escopo corrente.
  Retorna ponteiro para o Symbol criado.
  Em caso de redeclaração no mesmo escopo, imprime erro semântico e retorna NULL. */
Symbol *sym_declare(const char *name, int type, int category, int line, int column);

/* Busca um símbolo a partir do escopo corrente, subindo até o global.
  Retorna ponteiro para o Symbol encontrado, ou NULL se não declarado.
  Não imprime erro — cabe ao chamador reportar "undeclared identifier". */
Symbol *sym_lookup(const char *name);

/* Imprime o conteúdo completo da pilha de escopos (para depuração). */
void sym_print(void);

/* Converte SYM_TYPE_* para string legível. */
const char *sym_type_str(int type);

#endif /* SYMTABLE_H */
