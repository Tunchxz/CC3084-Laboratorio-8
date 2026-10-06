-- P2 - Porcentaje de los viajes de cada tipo de taxi por dia de la semana y hora de inicio.
-- Fuente: vista `viajes`. dia_semana: 1 = lunes ... 7 = domingo (ISO).
SELECT
    tipo,
    isodow(pickup_datetime)                                        AS dia_semana,
    hour(pickup_datetime)                                          AS hora,
    count(*)                                                       AS viajes,
    100.0 * count(*) / sum(count(*)) OVER (PARTITION BY tipo)      AS pct_viajes
FROM viajes
GROUP BY tipo, dia_semana, hora
ORDER BY tipo, dia_semana, hora;
