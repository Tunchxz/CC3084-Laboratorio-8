-- Indicador 2 - Participacion de los taxis verdes en el total de viajes, por mes.
-- Preguntas: Q2 (peso relativo de cada tipo de taxi).
-- Fuente: vista `viajes`. Destino: tabla destino.ind_02_participacion_verdes.
CREATE OR REPLACE TABLE destino.ind_02_participacion_verdes AS
SELECT
    periodo,
    count(*)                                                          AS viajes_total,
    count(*) FILTER (WHERE tipo = 'green')                            AS viajes_green,
    round(100.0 * count(*) FILTER (WHERE tipo = 'green') / count(*), 2) AS pct_green
FROM viajes
GROUP BY periodo
ORDER BY periodo;
