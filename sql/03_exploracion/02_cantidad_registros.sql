-- Ejercicio 3.2 - Cantidad de registros por archivo.
-- Fuente: data/raw/*/*/*.parquet (todos los tipos de taxi y años).
-- Salida: tipo, archivo y registros. Usa los metadatos Parquet (no lee los datos).
SELECT
    split_part(file_name, '/', 3)                  AS tipo,
    regexp_extract(file_name, '[^/]+$')            AS archivo,
    num_rows                                       AS registros
FROM parquet_file_metadata('data/raw/*/*/*.parquet')
ORDER BY tipo, archivo;
