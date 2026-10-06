-- Ejercicio 6.2 - Materializa la vista `viajes` como tabla en una base DuckDB.
-- Requiere: vista `viajes` (sql/04_eda/00_vista_viajes.sql) y la base destino adjunta como `destino`
--   (ATTACH 'data/processed/<archivo>.duckdb' AS destino).
-- Resultado: tabla destino.viajes con los viajes unificados y filtrados.
CREATE OR REPLACE TABLE destino.viajes AS
SELECT *
FROM viajes;
