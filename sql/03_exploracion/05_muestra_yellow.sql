-- Ejercicio 3.5 - Muestra aleatoria reproducible de taxis amarillos.
-- Fuente: data/raw/yellow/*/*.parquet.
SELECT *
FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true)
USING SAMPLE reservoir(5 ROWS) REPEATABLE (42);
