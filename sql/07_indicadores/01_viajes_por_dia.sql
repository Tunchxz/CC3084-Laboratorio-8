-- Indicador 1 - Viajes promedio por dia, por mes y tipo de taxi.
-- Preguntas: Q1 (evolucion de la demanda).
-- Fuente: vista `viajes`. Destino: tabla destino.ind_01_viajes_por_dia.
CREATE OR REPLACE TABLE destino.ind_01_viajes_por_dia AS
SELECT
    periodo,
    tipo,
    count(*)                                                     AS viajes,
    count(DISTINCT pickup_datetime::DATE)                        AS dias,
    round(count(*) / count(DISTINCT pickup_datetime::DATE), 0)   AS viajes_por_dia
FROM viajes
GROUP BY periodo, tipo
ORDER BY periodo, tipo;
