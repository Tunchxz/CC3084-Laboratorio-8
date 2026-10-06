-- P7 - Distribucion (percentiles) del total cobrado y de sus componentes por tipo de taxi.
-- Fuente: vista `viajes`.
UNPIVOT (
    SELECT
        tipo,
        avg(fare_amount)            AS fare_amount,
        avg(extra)                  AS extra,
        avg(mta_tax)                AS mta_tax,
        avg(tip_amount)             AS tip_amount,
        avg(tolls_amount)           AS tolls_amount,
        avg(improvement_surcharge)  AS improvement_surcharge,
        avg(coalesce(congestion_surcharge, 0)) AS congestion_surcharge,
        avg(coalesce(airport_fee, 0))          AS airport_fee,
        avg(cbd_congestion_fee)     AS cbd_congestion_fee,
        avg(total_amount)           AS total_amount
    FROM viajes
    GROUP BY tipo
)
ON COLUMNS(* EXCLUDE (tipo))
INTO NAME componente VALUE promedio
ORDER BY tipo, promedio DESC;
