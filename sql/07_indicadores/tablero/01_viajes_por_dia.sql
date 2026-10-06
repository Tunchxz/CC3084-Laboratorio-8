-- Tablero - Indicador 1: viajes promedio por dia, por mes y tipo de taxi.
-- Fuente: tablero.duckdb, tabla ind_01_viajes_por_dia.
SELECT periodo, tipo, viajes_por_dia
FROM ind_01_viajes_por_dia
ORDER BY periodo, tipo;
