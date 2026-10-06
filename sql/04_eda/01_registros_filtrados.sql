-- P0 - Registros conservados por la vista `viajes` frente al total de los archivos.
-- Fuente: data/raw/*/*/*.parquet (metadatos) y vista `viajes`.
WITH originales AS (
    SELECT split_part(file_name, '/', 3) AS tipo, sum(num_rows) AS registros_originales
    FROM parquet_file_metadata('data/raw/*/*/*.parquet')
    GROUP BY tipo
),
conservados AS (
    SELECT tipo, count(*) AS registros_conservados
    FROM viajes
    GROUP BY tipo
)
SELECT
    tipo,
    registros_originales,
    registros_conservados,
    registros_originales - registros_conservados                          AS registros_excluidos,
    round(100.0 * registros_conservados / registros_originales, 2)        AS pct_conservado
FROM originales
JOIN conservados USING (tipo)
ORDER BY tipo;
