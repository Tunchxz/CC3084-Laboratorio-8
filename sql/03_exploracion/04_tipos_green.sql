-- Ejercicio 3.4 - Tipos de datos de las columnas de taxis verdes.
-- Fuente: data/raw/green/*/*.parquet.
-- union_by_name=true integra columnas que solo existen en algunos archivos.
DESCRIBE
SELECT *
FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true);
