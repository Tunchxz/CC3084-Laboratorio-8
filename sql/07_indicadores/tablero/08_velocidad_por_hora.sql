-- Tablero - Indicador 8: velocidad promedio (mph) por hora de inicio, por tipo de taxi y año.
-- Fuente: tablero.duckdb, tabla ind_08_velocidad_por_hora.
SELECT hora, tipo || ' ' || anio AS serie, velocidad_mph
FROM ind_08_velocidad_por_hora
ORDER BY hora, serie;
