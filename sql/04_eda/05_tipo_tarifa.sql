-- P4 - Distribucion de viajes por tipo de tarifa (RatecodeID) y tipo de taxi.
-- Fuente: vista `viajes`. Codigos segun el diccionario de datos de la TLC.
SELECT
    tipo,
    CASE ratecode_id
        WHEN 1  THEN '1 Estandar'
        WHEN 2  THEN '2 JFK'
        WHEN 3  THEN '3 Newark'
        WHEN 4  THEN '4 Nassau/Westchester'
        WHEN 5  THEN '5 Negociada'
        WHEN 6  THEN '6 Viaje grupal'
        WHEN 99 THEN '99 Desconocido'
        ELSE 'Nulo'
    END                                                                AS tipo_tarifa,
    count(*)                                                           AS viajes,
    round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY tipo), 2) AS pct_viajes,
    round(avg(total_amount), 2)                                        AS total_promedio
FROM viajes
GROUP BY tipo, tipo_tarifa
ORDER BY tipo, tipo_tarifa;
