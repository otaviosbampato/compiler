#!/bin/bash

# Script para compilar arquivo Lex (.l) usando flex e gcc
# Base: executar a partir de src (ex.: ./scripts/compile.sh lexical2.l)
# Uso: ./scripts/compile.sh nomedoarquivo.l

if [ $# -eq 0 ]; then
    echo "Erro: Nenhum arquivo fornecido"
    echo "Uso: ./scripts/compile.sh nomedoarquivo.l"
    exit 1
fi

LEX_FILE=$1
LEX_NAME=$(basename "$LEX_FILE" .l)

echo "Compilando $LEX_FILE..."

# Passo 1: Gerar lex.yy.c com flex
echo "[1/2] Executando flex..."
flex -o bin/lex.yy.c "$LEX_FILE"
if [ $? -ne 0 ]; then
    echo "Erro ao executar flex"
    exit 1
fi
echo "✓ lex.yy.c gerado"

# Passo 2: Compilar com gcc
echo "[2/2] Compilando com gcc..."
gcc bin/lex.yy.c -ll -o bin/main
if [ $? -ne 0 ]; then
    echo "Erro ao compilar com gcc"
    exit 1
fi
echo "✓ Executável gerado em bin/main"

echo ""
echo "Compilação concluída com sucesso!"
echo "Para executar: ./scripts/run.sh <nomedoarquivo.txt>"
