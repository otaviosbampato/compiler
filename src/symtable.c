// * tabela de símbolos com escopos aninhados
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symtable.h"

extern int semantic_error_count;

Scope *current_scope = NULL;

// cria o escopo global (nível 0)
void sym_init(void) {
    Scope *global = (Scope *) malloc(sizeof(Scope));
    if (!global) { perror("sym_init: malloc"); exit(1); }
    global->symbols = NULL;
    global->parent  = NULL;
    global->level   = 0;
    current_scope   = global;
}

// empurra um novo escopo na pilha
void open_scope(void) {
    Scope *s = (Scope *) malloc(sizeof(Scope));
    if (!s) { perror("open_scope: malloc"); exit(1); }
    s->symbols     = NULL;
    s->parent      = current_scope;
    s->level       = current_scope ? current_scope->level + 1 : 0;
    current_scope  = s;
}

// limpa todos os símbolos
// atualiza o escopo atual
void close_scope(void) {
    if (!current_scope) {
        fprintf(stderr, "Erro interno: close_scope sem escopo aberto\n");
        return;
    }

    // libera todos os símbolos do escopo corrente
    Symbol *sym = current_scope->symbols;
    while (sym) {
        Symbol *next = sym->next;
        free(sym->name);
        free(sym);
        sym = next;
    }

    Scope *parent = current_scope->parent;
    free(current_scope);
    current_scope = parent;
}

// declara um símbolo no escopo corrente
Symbol *sym_declare(const char *name, int type, int category,
                    int line, int column) {

    if (!current_scope) {
        fprintf(stderr, "Erro interno: sym_declare sem escopo ativo\n");
        return NULL;
    }

    // percorre os símbolos, faz um strcmp e da erro se ja existe um symbol com aquele name
    for (Symbol *s = current_scope->symbols; s != NULL; s = s->next) {
        if (strcmp(s->name, name) == 0) {
            fprintf(stderr,
                "Erro semântico na linha %d, coluna %d: "
                "'%s' já declarado neste escopo (declaração anterior na linha %d)\n",
                line, column, name, s->line);
            semantic_error_count++;
            return NULL;
        }
    }

    // aloca e inicializa o novo símbolo
    Symbol *sym = (Symbol *) malloc(sizeof(Symbol));
    if (!sym) { perror("sym_declare: malloc"); exit(1); }


    sym->name        = strdup(name);
    sym->type        = type;
    sym->category    = category;
    sym->scope_level = current_scope->level;
    sym->line        = line;
    sym->column      = column;

    // insere no início da lista (mais rápido, ordem de declaração não importa)
    sym->next              = current_scope->symbols;
    current_scope->symbols = sym;

    return sym;
}

// busca símbolo do escopo corrente até o global
Symbol *sym_lookup(const char *name) {
    for (Scope *sc = current_scope; sc != NULL; sc = sc->parent) {
        for (Symbol *s = sc->symbols; s != NULL; s = s->next) {
            if (strcmp(s->name, name) == 0) return s;
        }
    }
    return NULL;  /* não encontrado */
}

// converte tipo para string
const char *sym_type_str(int type) {
    switch (type) {
        case SYM_TYPE_INT:   return "int";
        case SYM_TYPE_FLOAT: return "float";
        case SYM_TYPE_BOOL:  return "boolean";
        default:             return "";
    }
}

// imprime a tabela de simbolo, e passa por todos os escopos (topo → global)
void sym_print(void) {
    printf("\n=== TABELA DE SÍMBOLOS (escopos) ===\n");

    if (!current_scope) {
        printf("  (vazia)\n");
        return;
    }

    for (Scope *sc = current_scope; sc != NULL; sc = sc->parent) {
        printf("\n  Escopo nível %d:\n", sc->level);
        printf("  %-20s %-10s %-10s %s\n",
               "Nome", "Tipo", "Categoria", "Linha");
        printf("  %-20s %-10s %-10s %s\n",
               "----", "----", "---------", "-----");

        if (!sc->symbols) {
            printf("  (sem símbolos)\n");
            continue;
        }

        for (Symbol *s = sc->symbols; s != NULL; s = s->next) {
            const char *cat = (s->category == SYM_FUNC)  ? "função"    :
                              (s->category == SYM_PARAM) ? "parâmetro" : "variável";
            printf("  %-20s %-10s %-10s %d\n",
                   s->name, sym_type_str(s->type), cat, s->line);
        }
    }
    printf("\n");
}