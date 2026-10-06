-- Indicador 8 - Velocidad promedio (millas por hora) y duracion media por hora de inicio, por año y tipo.
-- Preguntas: Q9 (horas con trafico mas lento).
-- Fuente: vista `viajes`. velocidad = suma de distancias / suma de horas de viaje (se guardan ambas sumas).
-- Destino: tabla destino.ind_08_velocidad_por_hora.
CREATE OR REPLACE TABLE destino.ind_08_velocidad_por_hora AS
SELECT
    year(pickup_datetime)                                  AS anio,
    tipo,
    hour(pickup_datetime)                                  AS hora,
    count(*)                                               AS viajes,
    sum(trip_distance)                                     AS distancia_total_mi,
    sum(duracion_min) / 60                                 AS horas_total,
    round(sum(trip_distance) / (sum(duracion_min) / 60), 2) AS velocidad_mph,
    round(avg(duracion_min), 2)                            AS duracion_promedio_min
FROM viajes
GROUP BY anio, tipo, hora
ORDER BY anio, tipo, hora;
