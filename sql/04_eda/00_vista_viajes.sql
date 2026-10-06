-- Vista `viajes`: taxis amarillos y verdes unificados y filtrados.
-- Fuente: data/raw/yellow/*/*.parquet y data/raw/green/*/*.parquet (todos los años descargados).
-- Lee los Parquet en cada consulta; no materializa datos.
--
-- Columnas: nombres comunes en snake_case, `tipo` ('yellow' | 'green'), `periodo` (mes del
-- archivo, 'AAAA-MM') y `duracion_min`. `airport_fee` solo existe en yellow y `trip_type` en green.
-- `cbd_congestion_fee` se reporta como 0 en los archivos que no tienen la columna (anteriores a 2025).
--
-- Filtros aplicados (ver notebooks/03_exploracion.ipynb):
--   - inicio del viaje dentro del mes del archivo;
--   - fin posterior al inicio y duracion <= 24 h;
--   - distancia > 0 y <= 100 millas;
--   - total_amount >= 0.
CREATE OR REPLACE VIEW viajes AS
WITH unificado AS (
    SELECT
        'yellow'                AS tipo,
        filename,
        VendorID                AS vendor_id,
        tpep_pickup_datetime    AS pickup_datetime,
        tpep_dropoff_datetime   AS dropoff_datetime,
        passenger_count,
        trip_distance,
        RatecodeID              AS ratecode_id,
        PULocationID            AS pu_location_id,
        DOLocationID            AS do_location_id,
        payment_type,
        fare_amount,
        extra,
        mta_tax,
        tip_amount,
        tolls_amount,
        improvement_surcharge,
        congestion_surcharge,
        Airport_fee             AS airport_fee,
        coalesce(cbd_congestion_fee, 0) AS cbd_congestion_fee,
        total_amount,
        NULL::BIGINT            AS trip_type
    FROM read_parquet('data/raw/yellow/*/*.parquet', union_by_name = true, filename = true)
    UNION ALL BY NAME
    SELECT
        'green'                 AS tipo,
        filename,
        VendorID                AS vendor_id,
        lpep_pickup_datetime    AS pickup_datetime,
        lpep_dropoff_datetime   AS dropoff_datetime,
        passenger_count,
        trip_distance,
        RatecodeID              AS ratecode_id,
        PULocationID            AS pu_location_id,
        DOLocationID            AS do_location_id,
        payment_type,
        fare_amount,
        extra,
        mta_tax,
        tip_amount,
        tolls_amount,
        improvement_surcharge,
        congestion_surcharge,
        NULL::DOUBLE            AS airport_fee,
        coalesce(cbd_congestion_fee, 0) AS cbd_congestion_fee,
        total_amount,
        trip_type
    FROM read_parquet('data/raw/green/*/*.parquet', union_by_name = true, filename = true)
)
SELECT
    * EXCLUDE (filename),
    regexp_extract(filename, '(\d{4}-\d{2})\.parquet', 1)          AS periodo,
    date_diff('second', pickup_datetime, dropoff_datetime) / 60.0  AS duracion_min
FROM unificado
WHERE strftime(pickup_datetime, '%Y-%m') = regexp_extract(filename, '(\d{4}-\d{2})\.parquet', 1)
  AND dropoff_datetime > pickup_datetime
  AND dropoff_datetime - pickup_datetime <= INTERVAL 24 HOUR
  AND trip_distance > 0 AND trip_distance <= 100
  AND total_amount >= 0;
