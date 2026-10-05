-- Ejercicio 3.6 - Conteo de registros con posibles problemas de calidad por tipo de taxi.
-- Fuente: data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet.
-- Cada columna cuenta los registros que cumplen la condicion indicada en su nombre.
WITH viajes AS (
    SELECT
        'yellow'                                   AS tipo,
        filename,
        tpep_pickup_datetime                       AS pickup,
        tpep_dropoff_datetime                      AS dropoff,
        passenger_count, trip_distance, RatecodeID, payment_type,
        store_and_fwd_flag, congestion_surcharge,
        fare_amount, tip_amount, total_amount
    FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true, filename = true)
    UNION ALL
    SELECT
        'green',
        filename,
        lpep_pickup_datetime,
        lpep_dropoff_datetime,
        passenger_count, trip_distance, RatecodeID, payment_type,
        store_and_fwd_flag, congestion_surcharge,
        fare_amount, tip_amount, total_amount
    FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true, filename = true)
)
SELECT
    tipo,
    count(*)                                                              AS registros,
    count(*) FILTER (WHERE strftime(pickup, '%Y-%m')
                           <> regexp_extract(filename, '(\d{4}-\d{2})\.parquet', 1)) AS pickup_fuera_del_mes_del_archivo,
    count(*) FILTER (WHERE dropoff < pickup)                              AS dropoff_antes_de_pickup,
    count(*) FILTER (WHERE dropoff - pickup > INTERVAL 24 HOUR)           AS duracion_mayor_24h,
    count(*) FILTER (WHERE passenger_count IS NULL)                       AS pasajeros_nulos,
    count(*) FILTER (WHERE passenger_count IS NULL AND RatecodeID IS NULL
                       AND store_and_fwd_flag IS NULL AND congestion_surcharge IS NULL) AS nulos_simultaneos,
    count(*) FILTER (WHERE payment_type IS NULL)                          AS payment_type_nulo,
    count(*) FILTER (WHERE payment_type = 0)                              AS payment_type_0,
    count(*) FILTER (WHERE passenger_count = 0)                           AS pasajeros_cero,
    count(*) FILTER (WHERE trip_distance = 0)                             AS distancia_cero,
    count(*) FILTER (WHERE trip_distance > 100)                           AS distancia_mayor_100mi,
    count(*) FILTER (WHERE RatecodeID = 99)                               AS ratecode_99,
    count(*) FILTER (WHERE fare_amount < 0)                               AS tarifa_negativa,
    count(*) FILTER (WHERE total_amount < 0)                              AS total_negativo,
    count(*) FILTER (WHERE total_amount > 1000)                           AS total_mayor_1000,
    count(*) FILTER (WHERE tip_amount < 0)                                AS propina_negativa
FROM viajes
GROUP BY tipo
ORDER BY tipo;
