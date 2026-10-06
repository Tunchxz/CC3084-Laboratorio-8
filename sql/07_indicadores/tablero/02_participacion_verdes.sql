-- Tablero - Indicador 2: porcentaje de viajes realizados en taxis verdes, por mes.
-- Fuente: tablero.duckdb, tabla ind_02_participacion_verdes.
SELECT periodo, pct_green
FROM ind_02_participacion_verdes
ORDER BY periodo;
