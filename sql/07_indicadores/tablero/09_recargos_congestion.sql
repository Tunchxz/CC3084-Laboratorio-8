-- Tablero - Indicador 9: recargos por congestion como % del total cobrado, por mes y tipo de taxi.
-- Fuente: tablero.duckdb, tabla ind_09_recargos_congestion.
SELECT periodo, tipo, pct_del_total
FROM ind_09_recargos_congestion
ORDER BY periodo, tipo;
