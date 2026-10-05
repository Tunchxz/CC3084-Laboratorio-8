-- Ejercicio 3.6 - Perfil estadistico de taxis verdes (min, max, nulos, valores distintos).
-- Fuente: data/raw/green/*/*.parquet.
SUMMARIZE
SELECT *
FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true);
