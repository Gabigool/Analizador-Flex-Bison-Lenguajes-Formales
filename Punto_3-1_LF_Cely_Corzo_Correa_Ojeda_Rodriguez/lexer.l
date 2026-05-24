/**
 * Analizador Léxico para Reglas de Acceso (Flex)
 * 
 * Este archivo de Flex realiza el análisis léxico (tokenización) de reglas
 * de acceso. Identifica palabras clave, operadores, números, strings e identificadores
 * del lenguaje de control de acceso.
 */

%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include "parser.tab.h"

    /* Variable global para rastrear el número de línea actual */
    int linea_actual = 1;
%}

/* DEFINICIONES DE PATRONES LÉXICOS */

/* Patrón para una letra individual (mayúscula o minúscula) */
LETTER      [a-zA-Z]

/* Patrón para un dígito individual (0-9) */
DIGIT       [0-9]

/* Patrón para identificadores */
IDENTIFIER  {LETTER}({LETTER}|{DIGIT}|_)*

/* Patrón para números enteros positivos */
NUMBER      {DIGIT}+

/* Patrón para strings */
STRING      '([^'])*'

/* Patrón para espacios en blanco */
WHITESPACE  [ \t]+

/**  
 *  En esta sección se establecen las reglas que el lexer utiliza para 
 *  identificar y clasificar los tokens del lenguaje. Cada regla de reconocimiento
 *  asocia un patrón con la acción de retornar el token correspondiente hacia el
 *  analizador sintáctico. Se reconocen palabras clave para tipos de usuario y 
 *  roles, operadores lógicos y de comparación, símbolos delimitadores, así como
 *  números, cadenas de texto e identificadores empleados en las reglas de control
 *  de acceso.
 */

%%

"user"      { return USER; }
"admin"     { return ADMIN; }
"guest"     { return GUEST; }
"operator"  { return OPERATOR; }


"hour"      { return HOUR; }
"day"       { return DAY; }

"resource"  { return RESOURCE; }

"AND"       { return AND; }
"OR"        { return OR; }
"NOT"       { return NOT; }

">="        { return GREATER_EQ; }
"<="        { return LESS_EQ; }
"!="        { return NOT_EQUAL; }
">"         { return GREATER; }
"<"         { return LESS; }
"="         { return EQUAL; }

"("         { return LPAREN; }
")"         { return RPAREN; }

{NUMBER}    { 
    yylval.number = atoi(yytext); 
    return NUMBER; 
}

{STRING}    { 
    yylval.string = strdup(yytext); 
    return STRING; 
}

{IDENTIFIER} { 
    yylval.string = strdup(yytext); 
    return IDENTIFIER; 
}

{WHITESPACE} { }

"\n"         { 
    linea_actual++; 
}

.           { 
    printf("Carácter desconocido ignorado en línea %d: %s\n", linea_actual, yytext); 
}

%%

/* FUNCIÓN ESPECIAL DE FLEX */

/**
 * yywrap() - Función requerida por Flex
 * 
 * Retorna 1 para indicar que no hay más archivos a procesar
 */
int yywrap() {
    return 1;
}