-- Ejercicio 5 - Columnas cuyo tipo físico Parquet difiere entre años para un mismo tipo de taxi.
-- Fuente: data/raw/*/*/*.parquet (esquema).
SELECT
    split_part(file_name, '/', 3)                                       AS tipo,
    name                                                                AS columna,
    string_agg(DISTINCT split_part(file_name, '/', 4) || ': ' || type, ', ' ORDER BY split_part(file_name, '/', 4) || ': ' || type) AS tipos_por_anio
FROM parquet_schema('data/raw/*/*/*.parquet')
WHERE num_children IS NULL
GROUP BY tipo, columna
HAVING count(DISTINCT type) > 1
ORDER BY tipo, columna;
