#ifndef SYMTABLE_H
#define SYMTABLE_H

// Tipos suportados pela linguagem (espelham lexer.l)
#define SYM_TYPE_INT    1
#define SYM_TYPE_FLOAT  2
#define SYM_TYPE_BOOL   3

// Categorias de símbolo
#define SYM_VAR   0   /* variável local ou global */
#define SYM_FUNC  1   /* função */
#define SYM_PARAM 2   /* parâmetro formal */

// Type Widths (Bytes)
#define INT_WIDTH    4
#define FLOAT_WIDTH  8

// * listinha encadeada
typedef struct Symbol {
    char        *name;          // lexema do identificador          
    int          type;          // SYM_TYPE_*                       
    int          category;      // SYM_VAR | SYM_FUNC | SYM_PARAM  
    int          scope_level;   // nível de aninhamento (0 = global)
    int          line;          // linha da declaração              
    int          column;        // coluna da declaração             
    struct Symbol *next;        // próximo símbolo no mesmo escopo  
} Symbol;

typedef struct Scope {
    Symbol      *symbols;       // lista de símbolos deste escopo
    struct Scope *parent;       // escopo pai (NULL se global)
    int          level;         // nivel do escopo
} Scope;

extern Scope *current_scope;

void sym_init(void);

void open_scope(void);

void close_scope(void);

Symbol *sym_declare(const char *name, int type, int category, int line, int column);

Symbol *sym_lookup(const char *name);

void sym_print_all(void);

void sym_print_current_scope(void);

const char *sym_type_str(int type);

#endif
