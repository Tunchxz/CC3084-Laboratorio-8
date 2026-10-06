-- P8 - Valores atipicos e inconsistencias que permanecen en la vista `viajes`.
-- Fuente: vista `viajes`.
-- Atipico de total_amount segun regla IQR: > Q3 + 1.5 * (Q3 - Q1), calculado por tipo de taxi.
-- Cuartiles aproximados (approx_quantile).
WITH limites AS (
    SELECT
        tipo,
        approx_quantile(total_amount, 0.75)
            + 1.5 * (approx_quantile(total_amount, 0.75) - approx_quantile(total_amount, 0.25)) AS limite_iqr_total
    FROM viajes
    GROUP BY tipo
)
SELECT
    v.tipo,
    count(*)                                                                         AS viajes,
    round(any_value(l.limite_iqr_total), 2)                                          AS limite_iqr_total,
    count(*) FILTER (WHERE v.total_amount > l.limite_iqr_total)                      AS total_atipico_iqr,
    count(*) FILTER (WHERE v.trip_distance / (v.duracion_min / 60) > 80)             AS velocidad_mayor_80mph,
    count(*) FILTER (WHERE v.duracion_min < 1)                                       AS duracion_menor_1min,
    count(*) FILTER (WHERE v.total_amount = 0)                                       AS total_cero,
    count(*) FILTER (WHERE v.fare_amount > 0 AND v.tip_amount > v.fare_amount)       AS propina_mayor_tarifa,
    count(*) FILTER (WHERE abs(v.total_amount - (v.fare_amount + v.extra + v.mta_tax + v.tip_amount
                       + v.tolls_amount + v.improvement_surcharge + coalesce(v.congestion_surcharge, 0)
                       + coalesce(v.airport_fee, 0) + v.cbd_congestion_fee)) > 0.01)  AS total_no_cuadra
FROM viajes v
JOIN limites l USING (tipo)
GROUP BY v.tipo
ORDER BY v.tipo;
