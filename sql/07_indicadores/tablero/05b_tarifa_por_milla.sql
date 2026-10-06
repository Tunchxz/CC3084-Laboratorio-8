-- Tablero - Indicador 5b: tarifa base por milla (USD), por mes y tipo de taxi.
-- Fuente: tablero.duckdb, tabla ind_05_precio.
SELECT periodo, tipo, tarifa_por_milla
FROM ind_05_precio
ORDER BY periodo, tipo;
