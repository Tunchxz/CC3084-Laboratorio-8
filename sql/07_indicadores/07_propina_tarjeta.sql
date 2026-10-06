-- Indicador 7 - Propina como porcentaje de la tarifa base en viajes pagados con tarjeta, por mes y tipo.
-- Preguntas: Q8 (nivel de propinas). Solo tarjeta: las propinas en efectivo no se registran.
-- Fuente: vista `viajes`. Destino: tabla destino.ind_07_propina_tarjeta.
CREATE OR REPLACE TABLE destino.ind_07_propina_tarjeta AS
SELECT
    periodo,
    tipo,
    count(*)                                                              AS viajes_tarjeta,
    round(100.0 * sum(tip_amount) / sum(fare_amount), 2)                  AS pct_propina,
    round(100.0 * count(*) FILTER (WHERE tip_amount > 0) / count(*), 2)   AS pct_viajes_con_propina
FROM viajes
WHERE payment_type = 1 AND fare_amount > 0
GROUP BY periodo, tipo
ORDER BY periodo, tipo;
