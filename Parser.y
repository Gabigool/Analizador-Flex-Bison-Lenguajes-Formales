/**
 * Analizador Sintáctico con Bison para Reglas de Acceso
 * 
 * Este archivo de Bison realiza el análisis sintáctico (parsing) de reglas
 * de control de acceso. Valida la estructura gramatical y ejecuta acciones semánticas
 * para procesar los tokens generados por el analizador léxico.
 * 
 * Estructura de las reglas:
 *   - Inicio: USER [rol] [AND condiciones]
 *   - Condiciones: pueden ser de tiempo, recurso o personalizadas, unidos por AND/OR
 *   - Operadores lógicos: AND, OR, NOT (con precedencia y paréntesis)
 */

%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <time.h>

    // Se define el tipo de dato que Flex usa para los buffers de texto
    typedef struct yy_buffer_state *YY_BUFFER_STATE;
    
    // Se declaran las funciones externas de Flex que usamos en el main
    extern YY_BUFFER_STATE yy_scan_string(const char *str);
    extern void yy_delete_buffer(YY_BUFFER_STATE buffer);
    extern int yylex(void);
    extern FILE* yyin;

    void yyerror(const char *s);
%}

/* ============================================================================
   DEFINICIÓN DE TIPOS DE DATOS PARA VALORES SEMÁNTICOS
   ============================================================================ */

/**
 * %union - Define los tipos de datos que pueden almacenar los tokens y reglas
 * Cada token puede retornar un número, una cadena, o ambos
 */
%union {
    int number;       // Para valores numéricos (horas, comparaciones, etc.)
    char* string;     // Para identificadores, strings y valores textuales
}

/* DECLARACIÓN DE TOKENS */

// Palabras clave del dominio
%token USER ADMIN GUEST OPERATOR    // Tipos de usuarios
%token HOUR DAY RESOURCE            // Dimensiones de tiempo y recursos
%token AND OR NOT                   // Operadores lógicos
%token EQUAL NOT_EQUAL GREATER LESS GREATER_EQ LESS_EQ  // Operadores de comparación
%token LPAREN RPAREN                // Paréntesis

// Tokens con valores asociados
%token <number> NUMBER              // Números enteros con su valor
%token <string> STRING IDENTIFIER   // Strings e identificadores con su texto

/* DEFINICIÓN DE TIPOS DE RETORNO PARA REGLAS (NO-TERMINALES) */

%type <string> role_type            // Tipos de rol retornan cadenas
%type <number> value                // Valores pueden ser números

/* DIRECTIVAS DE PRECEDENCIA */

%left OR                            // Menor prioridad: OR asociativo a la izquierda
%left AND                           // Prioridad media: AND asociativo a la izquierda
%right NOT                          // Mayor prioridad: NOT asociativo a la derecha

// Símbolo de inicio de la gramática
%start lista_reglas


%%

/* REGLAS GRAMATICALES */

/**
 * lista_reglas - Punto de entrada: procesa una o más reglas de acceso
 * 
 * Estructura recursiva que permite múltiples reglas seguidas:
 *   - Una regla seguida de más reglas
 *   - O una sola regla
 */
lista_reglas:
    lista_reglas access_rule         // Agregando más reglas a la lista existente
    | access_rule                    // Primera regla de la lista
    ;

/**
 * access_rule - Define una regla de acceso válida
 * 
 * Estructura:
 *   1. USER [tipo] AND [condiciones] - Usuario con condiciones
 *   2. USER [tipo]                   - Solo usuario (sin condiciones)
 */
access_rule:
    user_clause AND logical_expression  { 
        printf("✓ Tipo: Usuario con condiciones -> Regla válida\n\n"); 
    }
    | user_clause                       { 
        printf("✓ Tipo: Solo usuario -> Regla válida\n\n"); 
    }
    ;

/**
 * user_clause - Cláusula de usuario (primera parte obligatoria)
 * 
 * Formato: USER [tipo_de_rol]
 * Especifica de qué tipo de usuario trata la regla
 */
user_clause:
    USER role_type                      { 
        printf("Analizando Usuario: %s\n", $2); 
    }
    ;

/**
 * role_type - Tipos de rol disponibles
 * 
 * Retorna: cadena con el nombre del rol
 * Opciones: admin, guest, operator
 */
role_type:
    ADMIN                               { $$ = "admin"; }
    | GUEST                             { $$ = "guest"; }
    | OPERATOR                          { $$ = "operator"; }
    ;

/**
 * logical_expression - Expresiones lógicas unificadas gracias a %left y %right
 */
logical_expression:
    condition
    | logical_expression OR logical_expression { 
        printf("  ↳ Operación lógica: OR\n"); 
    }
    | logical_expression AND logical_expression { 
        printf("  ↳ Operación lógica: AND\n"); 
    }
    | NOT logical_expression { 
        printf("  ↳ Operación lógica: NOT\n"); 
    }
    | LPAREN logical_expression RPAREN { 
        printf("  ↳ Grupo entre paréntesis ( )\n"); 
    }
    ;

/**
 * condition - Tipos de condiciones evaluables
 * 
 * Una regla puede tener tres tipos de condiciones:
 *   1. Basadas en tiempo (hora/día)
 *   2. Basadas en recursos
 *   3. Condiciones personalizadas
 */
condition:
    time_condition                              // Condiciones de hora o día
    | resource_condition                        // Condiciones de acceso a recursos
    | custom_condition                          // Condiciones personalizadas
    ;

/**
 * time_condition - Condiciones relacionadas con tiempo
 * 
 * Formatos:
 *   - HOUR [operador] [número]
 *   - DAY [operador] [día_semana]
 */
time_condition:
    HOUR comparison_op NUMBER           { 
        printf("    🔹 Condición de hora: %d\n", $3); 
    }
    | DAY comparison_op STRING          { 
        printf("    🔹 Condición de día: %s\n", $3); 
    }
    ;

/**
 * resource_condition - Condiciones relacionadas con recursos
 * 
 * Formatos:
 *   - RESOURCE [operador] [string]
 *   - RESOURCE [operador] [variable]
 */
resource_condition:
    RESOURCE comparison_op STRING       { 
        printf("    🔹 Condición de recurso: %s\n", $3); 
    }
    | RESOURCE comparison_op IDENTIFIER { 
        printf("    🔹 Condición de recurso (ID): %s\n", $3); 
    }
    ;

/**
 * custom_condition - Condiciones personalizadas definidas por el usuario
 * 
 * Formato: [variable] [operador] [valor]
 * Permite crear condiciones con identificadores personalizados
 */
custom_condition:
    IDENTIFIER comparison_op value      { 
        printf("    🔹 Condición personalizada: %s\n", $1); 
    }
    ;

/**
 * value - Valores que pueden usarse en condiciones
 * 
 * Puede ser:
 *   - Un número entero
 *   - Una cadena (entre comillas)
 *   - Un identificador (variable)
 */
value:
    NUMBER                              { $$ = $1; }      // Valor numérico
    | STRING                            { $$ = 0; }       // Valor de cadena
    | IDENTIFIER                        { $$ = 0; }       // Variable
    ;

/**
 * comparison_op - Operadores de comparación
 * 
 * Operadores disponibles:
 *   = (igual)
 *   != (diferente)
 *   > (mayor)
 *   < (menor)
 *   >= (mayor o igual)
 *   <= (menor o igual)
 */
comparison_op:
    EQUAL                               { printf("      [Op: =]"); }
    | NOT_EQUAL                         { printf("      [Op: !=]"); }
    | GREATER                           { printf("      [Op: >]"); }
    | LESS                              { printf("      [Op: <]"); }
    | GREATER_EQ                        { printf("      [Op: >=]"); }
    | LESS_EQ                           { printf("      [Op: <=]"); }
    ;

%%

/* FUNCIONES DE SOPORTE */

/**
 * Función encargada de reportar los errores sintácticos.
 */
void yyerror(const char *s) {
    printf("Error de Sintaxis: La estructura de esta regla es inválida.\n");
}

/* FUNCIÓN PRINCIPAL */

/**
 * main() - Punto de entrada del programa
 * 
 * Responsabilidades:
 *   1. Procesar argumentos de línea de comandos
 *   2. Obtener y mostrar timestamp del sistema
 *   3. Abrir archivo de entrada si se proporciona, o leer desde stdin
 *   4. Procesar línea por línea:
 *      - Mostrar contenido original de cada línea
 *      - Crear buffer dinámico de Flex (yy_scan_string)
 *      - Ejecutar analizador sintáctico
 *      - Validar estructura y reportar resultado
 *      - Liberar buffer de Flex
 *   5. Mantener estadísticas (reglas válidas e inválidas)
 *   6. Generar resumen estadístico final
 *   7. Retornar código de salida basado en errores encontrados
 * 
 * Parámetros:
 *   argc - Número de argumentos de línea de comandos
 *   argv - Array de argumentos
 *       argv[1] - (Opcional) Ruta del archivo a procesar
 * 
 * Retorna:
 *   0 - Si el análisis fue exitoso (sin errores sintácticos)
 *   1 - Si hubo errores en la apertura del archivo
 *   N - Número total de reglas con error estructural (código de salida)
 */
int main(int argc, char** argv) {
    printf("Analizador de Reglas de Acceso\n");
    printf("==================================\n");
    
    // Obtener el tiempo del sistema y formatearlo
    time_t tiempo_actual;
    struct tm *info_tiempo;
    char buffer_hora[80];
    time(&tiempo_actual);
    info_tiempo = localtime(&tiempo_actual);
    strftime(buffer_hora, sizeof(buffer_hora), "%Y-%m-%d %H:%M:%S", info_tiempo);
    printf("Fecha y Hora de Simulacion: %s\n", buffer_hora);
    printf("==================================\n");
    
    // Variables de control para las estadísticas del reporte final
    int reglas_validas = 0;
    int reglas_invalidas = 0;
    int linea_conteo = 1;

    // Verificar si se proporcionó un archivo como argumento
    if (argc > 1) {
        // Intentar abrir el archivo especificado
        FILE* file = fopen(argv[1], "r");
        if (!file) {
            printf("Error: No se puede abrir el archivo %s\n", argv[1]);
            return 1;  // Error al abrir archivo
        }
        
        printf("Procesando archivo: %s\n", argv[1]);
        printf("-----------------------------------\n");

        // Se lee el archivo renglón por renglón para poder mostrar el contenido original
        // e impedir que un error sintáctico detenga el análisis de las siguientes pruebas
        char buffer_linea[256];
        while (fgets(buffer_linea, sizeof(buffer_linea), file)) {
            // Eliminar el salto de línea al final para que la impresión en consola quede limpia
            buffer_linea[strcspn(buffer_linea, "\r\n")] = 0;
            
            // Omitir líneas completamente vacías
            if (strlen(buffer_linea) == 0) continue;

            printf("[Linea %d] Evaluando texto: \"%s\"\n", linea_conteo, buffer_linea);
            printf("-----------------------------------\n");

            // Alimentar dinámicamente a Flex con la línea actual en memoria
            YY_BUFFER_STATE buffer_flex = yy_scan_string(buffer_linea);
            
            // Ejecutar el analizador sintáctico para esta regla individual
            int result_linea = yyparse();
            
            if (result_linea == 0) {
                printf("  ↳ Result: ✓ REGLA VALIDA (Estructura aprobada)\n");
                reglas_validas++;
            } else {
                reglas_invalidas++;
            }

            // Liberar memoria asignada al buffer de Flex
            yy_delete_buffer(buffer_flex);
            printf("===================================\n\n");
            linea_conteo++;
        }
        
        // Cerrar el archivo si fue abierto
        fclose(file);

    } else {
        // Si no hay archivo, leer desde la entrada estándar (teclado)
        printf("Ingrese reglas de acceso (Presione ENTER para evaluar, Ctrl+D para salir):\n");
        printf("-----------------------------------\n");
        
        char buffer_teclado[256];
        // Bucle infinito que se ejecuta cada vez que el usuario escribe algo y da Enter
        while (printf("> "), fgets(buffer_teclado, sizeof(buffer_teclado), stdin)) {
            
            // Eliminar el salto de línea al final para limpiar el texto
            buffer_teclado[strcspn(buffer_teclado, "\r\n")] = 0;
            
            // Si el usuario da Enter en una línea vacía, ignorarla
            if (strlen(buffer_teclado) == 0) continue;
            
            printf("-----------------------------------\n");
            
            // Alimentar dinámicamente a Flex con la línea escrita en el teclado
            YY_BUFFER_STATE buffer_flex = yy_scan_string(buffer_teclado);
            
            // Ejecutar el analizador sintáctico inmediatamente para esta línea
            int result_linea = yyparse();
            
            if (result_linea == 0) {
                // Mensaje que confirma el éxito de la regla de forma inmediata
                printf("  ↳ Result: ✓ REGLA VALIDA (Estructura aprobada)\n");
                reglas_validas++;
            } else {
                reglas_invalidas++;
            }

            // Liberar el buffer de Flex y dejarlo listo para la siguiente línea del teclado
            yy_delete_buffer(buffer_flex);
            printf("===================================\n\n");
        }
    }
    
    printf("-----------------------------------\n");
    
    // Reportar el resultado del análisis (Tus condicionales originales de control)
    if (reglas_invalidas == 0) {
        printf("¡Análisis de lote completado sin colapsos!\n");
    } else {
        printf("El análisis finalizó con errores estructurales.\n");
    }
    
    // NÚMERO 3: RESUMEN ESTADÍSTICO DE COMPILACIÓN AL FINAL DEL INFORME
    // Muestra el balance numérico del lote solo si se procesó mediante archivo de texto
    if (argc > 1) {
        printf("\n-----------------------------------\n");
        printf("RESUMEN DEL ANALISIS SINTACTICO\n");
        printf("-----------------------------------\n");
        printf("Reglas Sintacticamente Correctas: %d\n", reglas_validas);
        printf("Reglas con Error Estructural:      %d\n", reglas_invalidas);
        printf("Total de casos procesados:         %d\n", reglas_validas + reglas_invalidas);
        printf("===================================\n");
    }
    
    // Retorna 0 si todo el lote fue perfecto, o el número de fallas como código de salida
    return reglas_invalidas; 
}