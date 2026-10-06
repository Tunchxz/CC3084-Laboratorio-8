-- Ejercicio 8 - Resumen anual de los indicadores por tipo de taxi, solo enero-agosto (comparable entre años).
-- Fuente: data/processed/tablero.duckdb (tablas ind_01, ind_05, ind_06, ind_07, ind_09).
-- Promedios ponderados por el numero de viajes de cada mes.
WITH mensual AS (
    SELECT
        left(v.periodo, 4)::INTEGER     AS anio,
        v.tipo,
        v.viajes,
        v.dias,
        p.total_promedio,
        p.tarifa_por_milla,
        t.viajes_tarjeta,
        t.pct_propina,
        r.pct_del_total                 AS pct_recargos,
        f.pct_efectivo,
        f.pct_tarjeta,
        f.pct_flex_sin_dato
    FROM ind_01_viajes_por_dia v
    JOIN ind_05_precio p USING (periodo, tipo)
    JOIN ind_07_propina_tarjeta t USING (periodo, tipo)
    JOIN ind_09_recargos_congestion r USING (periodo, tipo)
    JOIN (
        SELECT
            periodo,
            tipo,
            sum(pct_viajes) FILTER (WHERE forma_pago = 'Efectivo')             AS pct_efectivo,
            sum(pct_viajes) FILTER (WHERE forma_pago = 'Tarjeta')              AS pct_tarjeta,
            sum(pct_viajes) FILTER (WHERE forma_pago = 'Flex Fare / sin dato') AS pct_flex_sin_dato
        FROM ind_06_forma_pago
        GROUP BY periodo, tipo
    ) f USING (periodo, tipo)
    WHERE right(v.periodo, 2)::INTEGER BETWEEN 1 AND 8
)
SELECT
    anio,
    tipo,
    sum(viajes)                                                   AS viajes,
    round(sum(viajes) / sum(dias), 0)                             AS viajes_por_dia,
    round(sum(total_promedio * viajes) / sum(viajes), 2)          AS total_promedio,
    round(sum(tarifa_por_milla * viajes) / sum(viajes), 2)        AS tarifa_por_milla,
    round(sum(pct_propina * viajes_tarjeta) / sum(viajes_tarjeta), 2) AS pct_propina_tarjeta,
    round(sum(pct_recargos * viajes) / sum(viajes), 2)            AS pct_recargos,
    round(sum(pct_efectivo * viajes) / sum(viajes), 2)            AS pct_efectivo,
    round(sum(pct_tarjeta * viajes) / sum(viajes), 2)             AS pct_tarjeta,
    round(sum(pct_flex_sin_dato * viajes) / sum(viajes), 2)       AS pct_flex_sin_dato
FROM mensual
GROUP BY anio, tipo
ORDER BY tipo, anio;
