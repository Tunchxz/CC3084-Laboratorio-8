-- P3 - Distribucion de distancia, duracion, velocidad y pasajeros por tipo de taxi.
-- Fuente: vista `viajes`. Velocidad en millas por hora; pasajeros excluye nulos.
-- Percentiles aproximados (approx_quantile, t-digest): memoria constante sobre millones de filas.
UNPIVOT (
    SELECT
        tipo,
        approx_quantile(trip_distance, [0.25, 0.5, 0.75, 0.99])                     AS distancia_mi,
        approx_quantile(duracion_min, [0.25, 0.5, 0.75, 0.99])                      AS duracion_min,
        approx_quantile(trip_distance / (duracion_min / 60), [0.25, 0.5, 0.75, 0.99]) AS velocidad_mph,
        approx_quantile(passenger_count, [0.25, 0.5, 0.75, 0.99])                   AS pasajeros
    FROM viajes
    GROUP BY tipo
)
ON distancia_mi, duracion_min, velocidad_mph, pasajeros
INTO NAME metrica VALUE percentiles
ORDER BY metrica, tipo;
