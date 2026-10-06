-- Indicador 4 - Viajes promedio por dia segun el dia de la semana, por año y tipo de taxi.
-- Preguntas: Q4 (dias de mayor demanda).
-- Fuente: vista `viajes`. Destino: tabla destino.ind_04_viajes_por_dia_semana.
-- dia_semana: 1 = lunes ... 7 = domingo (ISO).
CREATE OR REPLACE TABLE destino.ind_04_viajes_por_dia_semana AS
SELECT
    year(pickup_datetime)                                                AS anio,
    tipo,
    isodow(pickup_datetime)                                              AS dia_semana,
    ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'][isodow(pickup_datetime)] AS dia,
    count(*)                                                             AS viajes,
    round(count(*) / count(DISTINCT pickup_datetime::DATE), 0)           AS viajes_por_dia
FROM viajes
GROUP BY anio, tipo, dia_semana, dia
ORDER BY anio, tipo, dia_semana;
