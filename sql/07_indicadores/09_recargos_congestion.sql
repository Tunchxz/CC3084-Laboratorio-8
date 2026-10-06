-- Indicador 9 - Recargos por congestion promedio por viaje y su peso en el total, por mes y tipo.
-- Preguntas: Q10 (aporte de los recargos por congestion al costo del viaje).
-- Fuente: vista `viajes`. Recargos: congestion_surcharge + cbd_congestion_fee.
-- Destino: tabla destino.ind_09_recargos_congestion.
CREATE OR REPLACE TABLE destino.ind_09_recargos_congestion AS
SELECT
    periodo,
    tipo,
    round(avg(coalesce(congestion_surcharge, 0)), 2)                    AS congestion_promedio,
    round(avg(cbd_congestion_fee), 2)                                   AS cbd_promedio,
    round(100.0 * sum(coalesce(congestion_surcharge, 0) + cbd_congestion_fee) / sum(total_amount), 2) AS pct_del_total
FROM viajes
GROUP BY periodo, tipo
ORDER BY periodo, tipo;
