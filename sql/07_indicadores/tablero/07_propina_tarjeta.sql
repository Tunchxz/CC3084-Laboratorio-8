-- Tablero - Indicador 7: propina como % de la tarifa base en viajes con tarjeta, por mes y tipo de taxi.
-- Fuente: tablero.duckdb, tabla ind_07_propina_tarjeta.
SELECT periodo, tipo, pct_propina
FROM ind_07_propina_tarjeta
ORDER BY periodo, tipo;
