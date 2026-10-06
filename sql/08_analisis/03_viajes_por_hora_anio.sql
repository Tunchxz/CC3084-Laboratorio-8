-- Ejercicio 8 - Porcentaje de viajes por hora de inicio, por año y tipo de taxi.
-- Fuente: data/processed/tablero.duckdb (tabla ind_03_viajes_por_hora).
SELECT anio, tipo, hora, pct_viajes
FROM ind_03_viajes_por_hora
ORDER BY tipo, anio, hora;
