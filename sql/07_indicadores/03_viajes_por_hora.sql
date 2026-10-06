-- Indicador 3 - Porcentaje de viajes por hora de inicio, por año y tipo de taxi.
-- Preguntas: Q3 (horas de mayor demanda).
-- Fuente: vista `viajes`. Destino: tabla destino.ind_03_viajes_por_hora.
CREATE OR REPLACE TABLE destino.ind_03_viajes_por_hora AS
SELECT
    year(pickup_datetime)                                                          AS anio,
    tipo,
    hour(pickup_datetime)                                                          AS hora,
    count(*)                                                                       AS viajes,
    round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY year(pickup_datetime), tipo), 2) AS pct_viajes
FROM viajes
GROUP BY anio, tipo, hora
ORDER BY anio, tipo, hora;
