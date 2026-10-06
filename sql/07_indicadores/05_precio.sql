-- Indicador 5 - Total promedio por viaje y tarifa base por milla, por mes y tipo de taxi.
-- Preguntas: Q5 (costo por viaje) y Q6 (tarifa por milla).
-- Fuente: vista `viajes`. Destino: tabla destino.ind_05_precio.
CREATE OR REPLACE TABLE destino.ind_05_precio AS
SELECT
    periodo,
    tipo,
    round(avg(total_amount), 2)                        AS total_promedio,
    round(sum(fare_amount) / sum(trip_distance), 2)    AS tarifa_por_milla
FROM viajes
GROUP BY periodo, tipo
ORDER BY periodo, tipo;
