-- Tablero - Indicador 6a: porcentaje de viajes por forma de pago y mes, taxis amarillos.
-- Fuente: tablero.duckdb, tabla ind_06_forma_pago.
SELECT periodo, forma_pago, pct_viajes
FROM ind_06_forma_pago
WHERE tipo = 'yellow'
ORDER BY periodo, forma_pago;
