-- P7 - Histograma del total cobrado (intervalos de 5 USD hasta 150 USD) por tipo de taxi.
-- Fuente: vista `viajes`. Valores > 150 se agrupan en el ultimo intervalo.
SELECT
    tipo,
    least(floor(total_amount / 5) * 5, 150)                         AS intervalo_desde,
    count(*)                                                        AS viajes,
    100.0 * count(*) / sum(count(*)) OVER (PARTITION BY tipo)       AS pct_viajes
FROM viajes
GROUP BY tipo, intervalo_desde
ORDER BY tipo, intervalo_desde;
