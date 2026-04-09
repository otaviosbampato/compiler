# README

## Sobre o projeto

O objetivo do trabalho prático é desenvolver um compilador para uma mini linguagem didática. O trabalho está dividido em 3 etapas, conforme a descrição a seguir.

## Lexical Analyzer

- Implemente um analisador léxico em Flex para a linguagem com os seguintes elementos:
  - Declarações de tipos (int, float);
  - Identificadores, números inteiros e decimais;
  - Palavras-chave (if, else, while, print, read);
  - Operadores relacionais, aritméticos e lógicos;
  - Símbolos de pontuação (; , ( ) { }).
- PS: tipo int pode assumir valores negativos.
- Critérios a serem avaliados:
  - Além de reconhecer os tokens, deve:
    - estar organizado, com comentários explicativos;
    - imprimir o token, seu lexema e sua posição (linha e coluna);
    - detectar erros e reportá-los ao usuário informando a posição;
    - exibir a tabela de símbolos construída pelo analisador léxico; e
    - desconsiderar espaços em branco e comentários (linha única // e múltipla /\* \*/).
  - O relatório (conciso e objetivo) deve:
    - discutir as decisões de projeto;
    - discutir as dificuldades encontradas;
    - apresentar dois diagramas de transição (DFAs) referentes a classes de tokens; e
    - incluir um arquivo de teste e sua saída (não precisa ser grande, porém completo).
