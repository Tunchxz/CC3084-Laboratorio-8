-- Ejercicio 3.5 - Muestra aleatoria reproducible de taxis verdes.
-- Fuente: data/raw/green/*/*.parquet.
SELECT *
FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true)
USING SAMPLE reservoir(5 ROWS) REPEATABLE (42);
