-- Tablero - Indicador 3: porcentaje de viajes por hora de inicio, por tipo de taxi y año.
-- Fuente: tablero.duckdb, tabla ind_03_viajes_por_hora.
SELECT hora, tipo || ' ' || anio AS serie, pct_viajes
FROM ind_03_viajes_por_hora
ORDER BY hora, serie;
