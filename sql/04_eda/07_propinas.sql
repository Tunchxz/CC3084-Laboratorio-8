-- P6 - Propina segun forma de pago y tipo de taxi.
-- Fuente: vista `viajes`. pct_propina = tip_amount / fare_amount (solo viajes con fare_amount > 0).
-- Mediana aproximada (approx_quantile).
SELECT
    tipo,
    CASE payment_type
        WHEN 0 THEN '0 Flex Fare'
        WHEN 1 THEN '1 Tarjeta'
        WHEN 2 THEN '2 Efectivo'
        WHEN 3 THEN '3 Sin cargo'
        WHEN 4 THEN '4 Disputa'
        ELSE 'Otro / Nulo'
    END                                                                       AS forma_pago,
    count(*)                                                                  AS viajes,
    round(100.0 * count(*) FILTER (WHERE tip_amount > 0) / count(*), 2)       AS pct_con_propina,
    round(avg(tip_amount), 2)                                                 AS propina_promedio,
    round(100 * approx_quantile(tip_amount / fare_amount, 0.5) FILTER (WHERE tip_amount > 0), 2) AS mediana_pct_propina_si_hay
FROM viajes
WHERE fare_amount > 0
GROUP BY tipo, forma_pago
ORDER BY tipo, forma_pago;
