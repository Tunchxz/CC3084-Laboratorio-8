-- Ejercicio 5.6 - Consulta conjunta 2024 + 2026 sobre la vista `viajes`.
-- Fuente: vista `viajes` (data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet).
-- Salida: por año y tipo, viajes, meses distintos, rango de fechas y métricas básicas.
SELECT
    year(pickup_datetime)                     AS anio,
    tipo,
    count(*)                                  AS viajes,
    count(DISTINCT periodo)                   AS meses,
    min(pickup_datetime)                      AS primer_viaje,
    max(pickup_datetime)                      AS ultimo_viaje,
    round(count(*) / count(DISTINCT pickup_datetime::DATE), 0) AS viajes_por_dia,
    round(avg(trip_distance), 2)              AS distancia_promedio,
    round(avg(total_amount), 2)               AS total_promedio
FROM viajes
GROUP BY anio, tipo
ORDER BY tipo, anio;
