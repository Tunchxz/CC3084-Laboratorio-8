-- Tablero - Indicador 6b: porcentaje de viajes por forma de pago y mes, taxis verdes.
-- Fuente: tablero.duckdb, tabla ind_06_forma_pago.
SELECT periodo, forma_pago, pct_viajes
FROM ind_06_forma_pago
WHERE tipo = 'green'
ORDER BY periodo, forma_pago;
