-- Ejercicio 5 - Columnas y tipos físicos Parquet por tipo de taxi y año.
-- Fuente: data/raw/*/*/*.parquet (esquema).
-- Salida: una fila por columna; cada celda indica en cuantos archivos de ese tipo/año aparece.
PIVOT (
    SELECT
        name                                                                  AS columna,
        split_part(file_name, '/', 3) || '_' || split_part(file_name, '/', 4) AS tipo_anio,
        file_name
    FROM parquet_schema('data/raw/*/*/*.parquet')
    WHERE num_children IS NULL
)
ON tipo_anio
USING count(file_name)
ORDER BY columna;
