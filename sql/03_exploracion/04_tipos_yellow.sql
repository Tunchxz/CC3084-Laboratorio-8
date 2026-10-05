-- Ejercicio 3.4 - Tipos de datos de las columnas de taxis amarillos.
-- Fuente: data/raw/yellow/*/*.parquet.
-- union_by_name=true integra columnas que solo existen en algunos archivos.
DESCRIBE
SELECT *
FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true);
