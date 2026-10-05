-- Ejercicio 3.6 - Perfil estadistico de taxis amarillos (min, max, nulos, valores distintos).
-- Fuente: data/raw/yellow/*/*.parquet.
SUMMARIZE
SELECT *
FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true);
