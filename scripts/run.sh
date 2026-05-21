#!/bin/bash

# Script para executar o lexer com arquivo de entrada
# Base: executar a partir de src (ex.: ./scripts/run.sh inputs/test-1.txt)
# Uso: ./scripts/run.sh caminho/relativo/do/arquivo.txt

if [ $# -eq 0 ]; then
    echo "Erro: Nenhum arquivo de entrada fornecido"
    echo "Uso: ./scripts/run.sh caminho/relativo/do/arquivo.txt"
    exit 1
fi

INPUT_FILE="$1"

# Verificar se o arquivo existe
if [ ! -f "$INPUT_FILE" ]; then
    echo "Erro: Arquivo '$INPUT_FILE' não encontrado"
    exit 1
fi

# Verificar se o executável foi compilado
if [ ! -f bin/main ]; then
    echo "Erro: Executável não encontrado. Execute compile.sh primeiro"
    exit 1
fi

echo "Executando lexer com entrada: $INPUT_FILE"
echo "================================="
bin/main "$INPUT_FILE"
echo "================================="
