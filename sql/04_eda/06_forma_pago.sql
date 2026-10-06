-- P5 - Forma de pago por tipo de taxi y mes (porcentaje de viajes).
-- Fuente: vista `viajes`. Codigos segun el diccionario de datos de la TLC.
SELECT
    tipo,
    periodo,
    CASE payment_type
        WHEN 0 THEN '0 Flex Fare'
        WHEN 1 THEN '1 Tarjeta'
        WHEN 2 THEN '2 Efectivo'
        WHEN 3 THEN '3 Sin cargo'
        WHEN 4 THEN '4 Disputa'
        WHEN 5 THEN '5 Desconocido'
        WHEN 6 THEN '6 Anulado'
        ELSE 'Nulo'
    END                                                                            AS forma_pago,
    count(*)                                                                       AS viajes,
    round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY tipo, periodo), 2)   AS pct_viajes
FROM viajes
GROUP BY tipo, periodo, forma_pago
ORDER BY tipo, periodo, forma_pago;
