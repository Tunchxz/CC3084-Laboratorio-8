-- Ejercicio 5 - Archivos disponibles por tipo de taxi y año, con el primer y ultimo mes.
-- Fuente: data/raw/*/*/*.parquet.
SELECT
    split_part(file, '/', 3)                                    AS tipo,
    split_part(file, '/', 4)                                    AS anio,
    count(*)                                                    AS archivos,
    min(regexp_extract(file, '(\d{4}-\d{2})\.parquet', 1))      AS primer_mes,
    max(regexp_extract(file, '(\d{4}-\d{2})\.parquet', 1))      AS ultimo_mes
FROM glob('data/raw/*/*/*.parquet')
GROUP BY tipo, anio
ORDER BY tipo, anio;
