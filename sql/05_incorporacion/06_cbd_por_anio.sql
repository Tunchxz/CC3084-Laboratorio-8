-- Ejercicio 5 - Valores nulos de cbd_congestion_fee por tipo de taxi y año del archivo.
-- Fuente: data/raw/*/*/*.parquet. Con union_by_name, una columna ausente en un archivo se lee como NULL.
SELECT
    split_part(filename, '/', 3)                                                    AS tipo,
    split_part(filename, '/', 4)                                                    AS anio,
    count(*)                                                                        AS registros,
    count(*) FILTER (WHERE cbd_congestion_fee IS NULL)                              AS cbd_nulos,
    round(100.0 * count(*) FILTER (WHERE cbd_congestion_fee IS NULL) / count(*), 2) AS pct_cbd_nulos
FROM read_parquet('data/raw/*/*/*.parquet', union_by_name = true, filename = true)
GROUP BY tipo, anio
ORDER BY tipo, anio;
