# Analizador Léxico y Sintáctico para Reglas de Acceso

## Descripción del Proyecto

Este proyecto implementa un **analizador léxico y sintáctico** completo para validar reglas de control de acceso en sistemas de gestión de usuarios. El analizador procesa y valida reglas de acceso que determinan qué usuarios o roles pueden acceder a recursos específicos bajo ciertas condiciones.

### Componentes Principales

- **Analizador Léxico (Lexer)**: Implementado con Flex, realiza la tokenización de las reglas de acceso, identificando palabras clave (USER, ADMIN, GUEST, OPERATOR), operadores lógicos (AND, OR, NOT), números, cadenas de texto e identificadores.

- **Analizador Sintáctico (Parser)**: Implementado con Bison, valida la estructura gramatical de las reglas de acceso y ejecuta acciones semánticas para procesar los tokens generados por el lexer.

- **Estructura de Reglas de Acceso**:
  ```
  USER [rol] [AND condiciones]
  ```
  Las condiciones pueden ser de tiempo, recurso o personalizadas, unidas por operadores lógicos AND/OR con soporte para paréntesis y precedencia de operadores.

## Requisitos Previos

Para compilar y ejecutar este proyecto en Linux, necesitas tener instaladas las siguientes herramientas:

```bash
sudo apt-get install -y flex bison gcc
```

### Instalación en diferentes distribuciones:

**Ubuntu/Debian:**
```bash
sudo apt-get install flex bison build-essential
```

**Fedora/RHEL:**
```bash
sudo dnf install flex bison gcc
```

**Arch Linux:**
```bash
sudo pacman -S flex bison base-devel
```

## Compilación desde Linux (Ignorar si ya se tiene el archivo "analizador")

Para compilar el proyecto, sigue estos pasos:

### 1. Generar el analizador sintáctico
```bash
bison -d Parser.y
```
Esto genera los archivos `parser.tab.c` (código del parser) y `parser.tab.h` (encabezados necesarios).

### 2. Generar el analizador léxico
```bash
flex lexer.l
```
Esto genera el archivo `lex.yy.c` que contiene el código C del lexer.

### 3. Compilar el ejecutable
```bash
gcc -o analizador lex.yy.c parser.tab.c -lfl
```

Este comando compila los archivos generados por Flex y Bison junto con la librería de Flex (`-lfl`) y produce el ejecutable `analizador`.

## Ejecución

Una vez compilado, puedes ejecutar el analizador de la siguiente manera:

### Procesar un archivo de entrada
```bash
./analizador < archivo_entrada.txt > output.txt
```

### Procesamiento interactivo
```bash
./analizador
```
Luego puedes escribir tus reglas de acceso directamente en la terminal.

## Archivos del Proyecto

- `lexer.l` - Definición del analizador léxico (Flex)
- `Parser.y` - Definición del analizador sintáctico (Bison)
- `lex.yy.c` - Código generado por Flex (no modificar)
- `parser.tab.c` - Código generado por Bison (no modificar)
- `parser.tab.h` - Encabezados generados por Bison (no modificar)
- `analizador` - Ejecutable compilado
- `pruebas.txt` - Archivo con casos de prueba de ejemplo
- `output.txt` - Archivo de salida con resultados del análisis

## Ejemplo de Uso

Crear un archivo `entrada.txt` con una regla de acceso:
```
USER ADMIN AND HOUR 9 TO 18 AND RESOURCE DATABASE
```

Ejecutar el analizador:
```bash
./analizador < entrada.txt > output.txt
```

Ver los resultados:
```bash
cat output.txt
```

## Script de Compilación Automática (Opcional)

Puedes crear un script `compile.sh` para automatizar todo el proceso:

```bash
#!/bin/bash
echo "Generando analizador léxico..."
flex lexer.l

echo "Generando analizador sintáctico..."
bison -d Parser.y

echo "Compilando..."
gcc -o analizador lex.yy.c parser.tab.c -lfl

echo "Compilación completada. Ejecutable: ./analizador"
```

Luego hazlo ejecutable y corre:
```bash
chmod +x compile.sh
./compile.sh
```

## Notas Importantes

- Los archivos `lex.yy.c` y `parser.tab.c` se generan automáticamente y no deben editarse manualmente.
- Si modificas `lexer.l` o `Parser.y`, debes regenerar los archivos correspondientes antes de compilar.
- El proyecto requiere compilación cada vez que se modifican los archivos de definición (`.l` o `.y`).

## Licencia

Este proyecto es un trabajo académico desarrollado como parte del curso de Lenguajes Formales.
