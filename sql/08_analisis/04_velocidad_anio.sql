-- Ejercicio 8 - Velocidad promedio (mph) por año y tipo de taxi: total del dia y franja 14:00-18:59.
-- Fuente: data/processed/tablero.duckdb (tabla ind_08_velocidad_por_hora).
SELECT
    anio,
    tipo,
    round(sum(distancia_total_mi) / sum(horas_total), 2)                              AS velocidad_dia_mph,
    round(sum(distancia_total_mi) FILTER (WHERE hora BETWEEN 14 AND 18)
          / sum(horas_total) FILTER (WHERE hora BETWEEN 14 AND 18), 2)                AS velocidad_tarde_mph
FROM ind_08_velocidad_por_hora
GROUP BY anio, tipo
ORDER BY tipo, anio;
