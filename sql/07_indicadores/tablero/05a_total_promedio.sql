-- Tablero - Indicador 5a: total promedio cobrado por viaje (USD), por mes y tipo de taxi.
-- Fuente: tablero.duckdb, tabla ind_05_precio.
SELECT periodo, tipo, total_promedio
FROM ind_05_precio
ORDER BY periodo, tipo;
