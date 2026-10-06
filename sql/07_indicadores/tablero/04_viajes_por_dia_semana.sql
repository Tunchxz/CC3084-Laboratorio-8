-- Tablero - Indicador 4: viajes por dia segun el dia de la semana, como indice (100 = promedio semanal),
-- por tipo de taxi y año.
-- Fuente: tablero.duckdb, tabla ind_04_viajes_por_dia_semana.
SELECT
    dia_semana || ' ' || dia                                                  AS dia,
    tipo || ' ' || anio                                                       AS serie,
    round(100.0 * viajes_por_dia / avg(viajes_por_dia) OVER (PARTITION BY tipo, anio), 1) AS indice
FROM ind_04_viajes_por_dia_semana
ORDER BY dia, serie;
