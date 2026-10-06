-- P1 - Viajes por mes y tipo de taxi, con promedio diario.
-- Fuente: vista `viajes`.
SELECT
    periodo,
    tipo,
    count(*)                                                 AS viajes,
    round(count(*) / count(DISTINCT pickup_datetime::DATE), 0) AS viajes_por_dia
FROM viajes
GROUP BY periodo, tipo
ORDER BY tipo, periodo;
