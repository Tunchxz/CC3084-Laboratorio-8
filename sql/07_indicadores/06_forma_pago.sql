-- Indicador 6 - Porcentaje de viajes por forma de pago, por mes y tipo de taxi.
-- Preguntas: Q7 (formas de pago predominantes y uso del efectivo).
-- Fuente: vista `viajes`. Codigos segun el diccionario de datos de la TLC; 3-6 se agrupan como 'Otro'.
-- Destino: tabla destino.ind_06_forma_pago.
CREATE OR REPLACE TABLE destino.ind_06_forma_pago AS
SELECT
    periodo,
    tipo,
    forma_pago,
    count(*)                                                                      AS viajes,
    round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY periodo, tipo), 2)  AS pct_viajes
FROM (
    SELECT
        periodo,
        tipo,
        CASE
            WHEN payment_type = 1 THEN 'Tarjeta'
            WHEN payment_type = 2 THEN 'Efectivo'
            WHEN payment_type = 0 OR payment_type IS NULL THEN 'Flex Fare / sin dato'
            ELSE 'Otro'
        END AS forma_pago
    FROM viajes
)
GROUP BY periodo, tipo, forma_pago
ORDER BY periodo, tipo, forma_pago;
