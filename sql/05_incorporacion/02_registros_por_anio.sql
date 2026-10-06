-- Ejercicio 5 - Registros por tipo de taxi y año según los metadatos Parquet (no lee los datos).
-- Fuente: data/raw/*/*/*.parquet.
SELECT
    split_part(file_name, '/', 3)   AS tipo,
    split_part(file_name, '/', 4)   AS anio,
    sum(num_rows)                   AS registros
FROM parquet_file_metadata('data/raw/*/*/*.parquet')
GROUP BY tipo, anio
ORDER BY tipo, anio;
