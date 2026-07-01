#!/bin/bash

# Script unificado: compila e executa, salvando saída em output/output.txt
# Uso: ./run.sh caminho/para/input.txt

if [ $# -eq 0 ]; then
    echo "Erro: Nenhum arquivo de entrada fornecido"
    echo "Uso: ./run.sh caminho/para/input.txt"
    exit 1
fi

INPUT_FILE="$1"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Erro: Arquivo '$INPUT_FILE' não encontrado"
    exit 1
fi

# Diretórios
SRC_DIR="src"
BIN_DIR="bin"
OUT_DIR="output"
OUT_FILE="$OUT_DIR/output.txt"

mkdir -p "$BIN_DIR" "$OUT_DIR"

# Compilação
echo "Iniciando compilação do Lexer e Parser..."

echo "[1/3] Executando bison..."
bison -Wall -d -o "$BIN_DIR/parser.c" "$SRC_DIR/parser.y"
if [ $? -ne 0 ]; then
    echo "Erro ao executar bison no arquivo parser.y"
    exit 1
fi
echo "✓ parser.c e parser.h gerados em $BIN_DIR"

echo "[2/3] Executando flex..."
flex -o "$BIN_DIR/lexer.c" "$SRC_DIR/lexer.l"
if [ $? -ne 0 ]; then
    echo "Erro ao executar flex no arquivo lexer.l"
    exit 1
fi
echo "✓ lexer.c gerado em $BIN_DIR"

echo "[3/3] Compilando com gcc..."
gcc -I"$SRC_DIR" -o "$BIN_DIR/main" \
    "$BIN_DIR/parser.c" "$BIN_DIR/lexer.c" \
    "$SRC_DIR/utils.c" "$SRC_DIR/temporary.c" \
    "$SRC_DIR/tac-generator.c" "$SRC_DIR/symtable.c" \
    -lfl
if [ $? -ne 0 ]; then
    echo "Erro ao compilar com gcc"
    exit 1
fi
echo "✓ Executável gerado em $BIN_DIR/main"

echo ""
echo "Compilação concluída com sucesso!"

# Execução
echo ""
echo "Executando com entrada: $INPUT_FILE"
echo "Saída será salva em:    $OUT_FILE"
echo "================================="

bin/main "$INPUT_FILE" | tee "$OUT_FILE"

echo "================================="
echo "✓ Saída salva em $OUT_FILE"