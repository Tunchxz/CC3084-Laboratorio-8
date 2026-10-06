-- P8 - Diferencia entre total_amount y la suma de sus componentes, por tipo de taxi y forma de pago.
-- Fuente: vista `viajes`. diferencia = total_amount - suma de componentes; "no cuadra" si |diferencia| > 0.01.
-- Mediana aproximada (approx_quantile).
WITH diferencias AS (
    SELECT
        tipo,
        payment_type,
        total_amount - (fare_amount + extra + mta_tax + tip_amount + tolls_amount + improvement_surcharge
                        + coalesce(congestion_surcharge, 0) + coalesce(airport_fee, 0) + cbd_congestion_fee) AS diferencia
    FROM viajes
)
SELECT
    tipo,
    payment_type,
    count(*)                                                                   AS viajes,
    count(*) FILTER (WHERE abs(diferencia) > 0.01)                             AS no_cuadra,
    round(100.0 * count(*) FILTER (WHERE abs(diferencia) > 0.01) / count(*), 2) AS pct_no_cuadra,
    round(approx_quantile(diferencia, 0.5) FILTER (WHERE abs(diferencia) > 0.01), 2) AS mediana_diferencia
FROM diferencias
GROUP BY tipo, payment_type
ORDER BY tipo, payment_type;
