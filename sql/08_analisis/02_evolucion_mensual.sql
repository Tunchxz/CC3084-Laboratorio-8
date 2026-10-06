-- Ejercicio 8 - Evolucion mensual de los indicadores principales por tipo de taxi (todos los meses).
-- Fuente: data/processed/tablero.duckdb (tablas ind_01, ind_02, ind_05, ind_06, ind_09).
SELECT
    v.periodo,
    v.tipo,
    v.viajes_por_dia,
    g.pct_green,
    p.total_promedio,
    p.tarifa_por_milla,
    r.cbd_promedio,
    f.pct_viajes                AS pct_efectivo
FROM ind_01_viajes_por_dia v
JOIN ind_02_participacion_verdes g USING (periodo)
JOIN ind_05_precio p USING (periodo, tipo)
JOIN ind_09_recargos_congestion r USING (periodo, tipo)
JOIN ind_06_forma_pago f ON f.periodo = v.periodo AND f.tipo = v.tipo AND f.forma_pago = 'Efectivo'
ORDER BY v.tipo, v.periodo;
