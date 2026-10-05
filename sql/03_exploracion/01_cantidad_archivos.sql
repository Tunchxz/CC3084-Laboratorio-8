-- Ejercicio 3.1 - Cantidad de archivos Parquet disponibles.
-- Fuente: data/raw/*/*/*.parquet (todos los tipos de taxi y años).
-- Salida: tipo de taxi, año y cantidad de archivos.
SELECT
    split_part(file, '/', 3) AS tipo,
    split_part(file, '/', 4) AS anio,
    count(*)                 AS archivos
FROM glob('data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY tipo, anio;
