-- Ejercicio 3.3 - Columnas presentes en los archivos y en cuantos archivos aparece cada una.
-- Fuente: data/raw/*/*/*.parquet (esquema Parquet de cada archivo).
-- Salida: columna, archivos yellow y archivos green en los que aparece.
SELECT
    name                                                          AS columna,
    count(*) FILTER (WHERE split_part(file_name, '/', 3) = 'yellow') AS archivos_yellow,
    count(*) FILTER (WHERE split_part(file_name, '/', 3) = 'green')  AS archivos_green
FROM parquet_schema('data/raw/*/*/*.parquet')
WHERE num_children IS NULL          -- excluye el nodo raiz del esquema
GROUP BY columna
ORDER BY archivos_yellow = 0, archivos_green = 0, columna;
