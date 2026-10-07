# Laboratorio 8 – Respuestas

Preguntas del laboratorio que no tienen un espacio específico en notebooks o scripts.

## Estructura del proyecto

**Explique cuál considera que es el propósito de cada directorio.**

| Directorio / archivo | Propósito                                                                                             |
| -------------------- | ----------------------------------------------------------------------------------------------------- |
| `data/raw/`          | Archivos Parquet originales descargados de la TLC, organizados como `<tipo>/<año>/`. No se modifican. |
| `data/processed/`    | Datos derivados: bases DuckDB materializadas y resultados intermedios.                                |
| `notebooks/`         | Notebooks de exploración, análisis y benchmarks.                                                      |
| `scripts/`           | Código ejecutable reutilizable (descarga de datos, benchmarks, tablero).                              |
| `sql/`               | Consultas SQL documentadas, separadas del código que las ejecuta.                                     |
| `docs/`              | Documentación del proyecto, respuestas y evidencia (capturas del tablero).                            |

## Ejercicio 1

### 1.1–1.2 Fork y clonación

El trabajo se realiza sobre el repositorio propio `Tunchxz/CC3084-Laboratorio-8`, clonado localmente. El ambiente se levantó con `docker compose up --build -d`.

### 1.3 Verificación de los servicios

| Servicio                   | Estado                 | Verificación                     | Resultado                              |
| -------------------------- | ---------------------- | -------------------------------- | -------------------------------------- |
| `lab8-lab` (JupyterLab)    | `running`, puerto 8888 | `curl localhost:8888/api`        | `{"version": "2.21.1"}`                |
| `lab8-metabase` (Metabase) | `running`, puerto 3000 | `curl localhost:3000/api/health` | `{"status":"ok"}` (versión `v0.63.19`) |

### 1.4 Herramientas disponibles en el ambiente

| Contenedor      | Herramienta                 | Versión  |
| --------------- | --------------------------- | -------- |
| `lab8-lab`      | Python                      | 3.11.14  |
|                 | DuckDB                      | 1.5.5    |
|                 | JupyterLab                  | 4.6.4    |
|                 | pandas                      | 3.0.6    |
|                 | pyarrow                     | 25.0.1   |
|                 | matplotlib                  | 3.11.2   |
|                 | requests                    | 2.34.2   |
|                 | numpy                       | 2.4.6    |
|                 | curl                        | 8.14.1   |
| `lab8-metabase` | Metabase                    | v0.63.19 |
|                 | Java (OpenJDK)              | 21       |
|                 | Driver DuckDB para Metabase | 1.5.5.0  |

### 1.6 ¿Por qué es importante un ambiente reproducible?

- **Mismos resultados en cualquier máquina:** las versiones de Python, DuckDB y demás librerías están fijadas en `requirements.txt` y en los Dockerfiles, por lo que el análisis no depende de lo que tenga instalado cada persona.
- **Compatibilidad entre componentes:** la versión de `duckdb` debe coincidir con la del driver de Metabase; fijarlas evita que una base creada en Python no pueda abrirse en el tablero.
- **Puesta en marcha rápida:** un solo comando (`docker compose up --build`) deja listo todo el ambiente.
- **Verificabilidad:** otra persona puede repetir la descarga, las consultas y los benchmarks y comprobar los resultados.

## Ejercicio 2

### 2.1 Análisis del script proporcionado

El script original ya:

- consultaba al servidor (`HEAD`) qué meses estaban publicados;
- omitía archivos existentes con tamaño mayor a 0;
- descargaba a un archivo temporal `.part` con reintentos.

Al ejecutarlo sin cambios descargó correctamente los 16 archivos publicados de 2026. Las partes que debían modificarse eran:

- **Año fijo:** la constante `ANIO = 2026` se usaba en todas las funciones, por lo que el script no podía obtener otros años.
- **Ruta relativa:** `DIR_DESTINO = Path("data/raw")` dependía del directorio desde el que se ejecutara el script.

### 2.6 Cambios realizados al script

| Cambio             | Detalle                                                                                            |
| ------------------ | -------------------------------------------------------------------------------------------------- |
| Año parametrizable | `ANIO` se reemplazó por el argumento `--anio` (uno o varios años; por defecto `2026`).             |
| Funciones con año  | `construir_nombre`, `construir_url`, `ruta_destino` y `descargar` reciben `anio`.                  |
| Ciclo por año      | `main()` recorre cada año y tipo de taxi y acumula un único resumen.                               |
| Ruta absoluta      | `DIR_DESTINO` se calcula desde la ubicación del script, por lo que siempre escribe en `data/raw/`. |
| Docstrings         | Actualizados para varios años.                                                                     |

Resultados de ejecución:

| Ejecución                            | Descargados | Ya existían | No publicados | Fallidos |
| ------------------------------------ | ----------- | ----------- | ------------- | -------- |
| 1ª (script original)                 | 16          | 0           | 8             | 0        |
| 2ª (script modificado, desde `/tmp`) | 0           | 16          | 8             | 0        |

### 2.7 ¿Cómo se determinó que el conjunto descargado está completo?

1. **Meses publicados:** el servidor de la TLC responde `200` para enero–agosto de 2026 y `403` para septiembre–diciembre, tanto en amarillos como en verdes. Se esperaban, por tanto, **16 archivos** (8 × 2), y se obtuvieron 16.
2. **Integridad de bytes:** el tamaño de cada archivo local coincide exactamente con el `Content-Length` informado por el servidor (16/16).
3. **Legibilidad:** DuckDB leyó los 16 archivos sin errores y devolvió registros para cada uno:

| Mes     |    Yellow |  Green |
| ------- | --------: | -----: |
| 2026-01 | 3,724,889 | 40,272 |
| 2026-02 | 3,399,866 | 37,373 |
| 2026-03 | 3,952,451 | 44,208 |
| 2026-04 | 3,831,240 | 44,238 |
| 2026-05 | 4,090,836 | 44,921 |
| 2026-06 | 3,837,248 | 44,163 |
| 2026-07 | 3,530,109 | 41,252 |
| 2026-08 | 3,336,716 | 40,687 |

4. **Idempotencia:** una segunda ejecución no descargó nada (16 "ya existían").

## Ejercicio 3

Las consultas (3.1–3.8) están en `sql/03_exploracion/` y su documentación (objetivo, fuente, resultado y decisión) en `notebooks/03_exploracion.ipynb`.

### 3.9 ¿Qué significa consultar directamente un archivo Parquet y por qué es útil con grandes volúmenes?

Consultar directamente un archivo Parquet significa que DuckDB lee el archivo en el momento de ejecutar la consulta (`FROM read_parquet('data/raw/...')`), sin cargar ni copiar antes los datos a una tabla o base de datos.

Es útil con grandes volúmenes porque:

- **No hay paso de carga:** los 30 millones de registros de 2026 se consultaron en cuanto se descargaron, sin duplicar los datos en disco.
- **Solo se lee lo necesario:** Parquet guarda los datos por columnas, así que DuckDB lee únicamente las columnas que usa la consulta y puede saltarse bloques de filas mediante las estadísticas (mín./máx.) del archivo.
- **Uso de metadatos:** algunas preguntas se responden sin leer los datos. El conteo de registros (`parquet_file_metadata`) y el esquema (`parquet_schema`) se obtuvieron en menos de un segundo.
- **Archivos nuevos sin cambios:** un patrón como `data/raw/*/*/*.parquet` incluye automáticamente los archivos nuevos que se agreguen a la carpeta.
- **Memoria acotada:** DuckDB procesa los datos por bloques, por lo que no necesita que todo el conjunto quepa en memoria.

## Ejercicio 4

Las preguntas, consultas (`sql/04_eda/`), resultados y hallazgos están documentados en `notebooks/04_eda.ipynb`.

## Ejercicio 5

La descarga, la verificación, las consultas de validación (`sql/05_incorporacion/`) y la revisión de las consultas anteriores (5.1–5.8) están documentadas en `notebooks/05_incorporacion_2024.ipynb`.

### 5.9 ¿Qué características del diseño permiten incorporar nuevos archivos sin modificar todo el flujo?

- **Año como parámetro:** el script de descarga recibe los años con `--anio`; incorporar 2024 no requirió cambiar su código.
- **Descarga idempotente:** los archivos existentes se omiten, por lo que el script puede ejecutarse con todos los años cada vez sin repetir descargas.
- **Estructura de carpetas fija:** cada archivo se guarda en `data/raw/<tipo>/<año>/` con su nombre original, de modo que el tipo, el año y el mes se pueden obtener de la ruta.
- **Consultas con patrones de archivos:** las consultas leen `data/raw/<tipo>/*/*.parquet` en lugar de archivos específicos, así que los archivos nuevos se incluyen automáticamente.
- **`union_by_name = true`:** combina archivos con esquemas distintos (columnas que aparecen o desaparecen entre años) sin fallar.
- **Vista única (`viajes`):** la unificación de columnas, los filtros de calidad y los ajustes por año (como `coalesce(cbd_congestion_fee, 0)`) se definen en un solo archivo. Un cambio ahí se aplica a todas las consultas que la usan.
- **Lectura directa de Parquet:** como no hay tablas que recargar, los archivos nuevos quedan disponibles para consulta en cuanto se descargan.

## Ejercicio 6

Las consultas, los tiempos, la tabla de resultados y el análisis de las diferencias (6.1–6.9) están en `notebooks/06_benchmark.ipynb`. El benchmark se ejecuta con `scripts/benchmark.py` y sus resultados se guardan en `docs/benchmark/`.

### 6.10 ¿Cuándo consultar directamente Parquet y cuándo materializar una tabla?

**Consultar Parquet directamente** es apropiado cuando:

- el análisis es **exploratorio o se ejecuta pocas veces**: crear la tabla de 2024 + 2026 tomó 81 s, y ese costo solo se recupera si el análisis se ejecuta al menos dos veces;
- **llegan archivos nuevos con frecuencia**, como en este laboratorio: los Parquet se consultan en cuanto se descargan, mientras que una tabla habría que recargarla o actualizarla;
- el **espacio en disco es limitado**: la base DuckDB ocupó casi el doble que los Parquet y duplica los datos;
- los datos se **comparten con otras herramientas** (pandas, Spark, otros motores), porque Parquet es un formato abierto.

**Materializar una tabla DuckDB** conviene cuando:

- las **mismas consultas se repiten muchas veces** sobre datos que cambian poco, como en un tablero o en reportes periódicos. La tabla fue 2.3–2.6 veces más rápida en el conjunto de consultas y hasta 7 veces en agregaciones simples;
- las transformaciones son **costosas y siempre las mismas** (unir tipos de taxi, filtrar, calcular columnas): en la tabla se hacen una sola vez;
- se necesita **actualizar datos** (`UPDATE`, `DELETE`), algo que los archivos Parquet no permiten;
- la base **cabe en la memoria disponible**: en ese caso DuckDB conserva los bloques en memoria entre consultas y la ventaja es mayor.

Una estrategia combinada es conservar los Parquet como fuente original y materializar solo el subconjunto o las agregaciones que se consultan con más frecuencia (por ejemplo, las del tablero del Ejercicio 7).

## Ejercicio 7

Tablero en Metabase: **"Viajes de taxi NYC - Indicadores"** (<http://localhost:3000/dashboard/2>). Evidencia: `docs/tablero/tablero_2024_2026.png`.

Datos utilizados: 2024 (enero–diciembre) y 2026 (enero–agosto), taxis amarillos y verdes, filtrados con la vista `viajes`.

### Construcción

| Paso | Archivo                            | Descripción                                                                                                                             |
| ---- | ---------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| 1    | `sql/07_indicadores/NN_*.sql`      | Cada consulta crea una tabla agregada `ind_NN_*` a partir de la vista `viajes`.                                                         |
| 2    | `scripts/indicadores.py`           | Ejecuta esas consultas y genera `data/processed/tablero.duckdb` (tablas pequeñas: de 20 a 160 filas).                                   |
| 3    | `sql/07_indicadores/tablero/*.sql` | Consulta de cada visualización sobre las tablas `ind_*`.                                                                                |
| 4    | `scripts/tablero_metabase.py`      | Crea por la API de Metabase la conexión DuckDB (solo lectura, `memory_limit = 256MB`), una pregunta SQL por visualización y el tablero. |

Metabase consulta tablas ya agregadas y no los 69 millones de viajes, por lo que el tablero responde rápido y no compite por memoria con el análisis.

### 7.1 Preguntas de análisis

| #   | Pregunta                                                               |
| --- | ---------------------------------------------------------------------- |
| Q1  | ¿Cómo evoluciona la demanda de viajes mes a mes?                       |
| Q2  | ¿Qué proporción de los viajes realizan los taxis verdes y cómo cambia? |
| Q3  | ¿En qué horas se concentra la demanda?                                 |
| Q4  | ¿Qué días de la semana tienen más viajes?                              |
| Q5  | ¿Cuánto paga en promedio un pasajero por viaje y cómo cambia?          |
| Q6  | ¿Cuál es la tarifa base por milla y cómo cambia?                       |
| Q7  | ¿Qué formas de pago predominan y disminuye el uso de efectivo?         |
| Q8  | ¿Qué porcentaje de propina dejan los pasajeros que pagan con tarjeta?  |
| Q9  | ¿En qué horas el tráfico es más lento?                                 |
| Q10 | ¿Cuánto aportan los recargos por congestión al costo del viaje?        |

### 7.2, 7.6 y 7.7 Indicadores, justificación y consultas

| Indicador                        | Pregunta | Definición                                      | Visualización                  | Justificación                                                                              | Consultas                                             |
| -------------------------------- | -------- | ----------------------------------------------- | ------------------------------ | ------------------------------------------------------------------------------------------ | ----------------------------------------------------- |
| 1. Viajes promedio por día       | Q1       | Viajes / días con viajes, por mes y tipo        | Líneas (verde en eje derecho)  | El promedio diario corrige la diferencia de días entre meses y mide la demanda.            | `01_viajes_por_dia.sql`, `tablero/01_*`               |
| 2. Participación de taxis verdes | Q2       | % de viajes del mes realizados por taxis verdes | Línea                          | Mide el peso relativo de cada servicio, independiente del volumen total.                   | `02_participacion_verdes.sql`, `tablero/02_*`         |
| 3. Viajes por hora               | Q3       | % de los viajes del tipo por hora de inicio     | Líneas                         | Identifica las horas pico; en porcentaje se comparan tipos con volúmenes distintos.        | `03_viajes_por_hora.sql`, `tablero/03_*`              |
| 4. Viajes por día de la semana   | Q4       | Índice: viajes del día / promedio semanal × 100 | Barras                         | Muestra qué días están por encima o por debajo del promedio de cada tipo.                  | `04_viajes_por_dia_semana.sql`, `tablero/04_*`        |
| 5a. Total promedio por viaje     | Q5       | Promedio de `total_amount`                      | Líneas                         | Es el costo final para el pasajero, incluidos recargos y propina.                          | `05_precio.sql`, `tablero/05a_*`                      |
| 5b. Tarifa por milla             | Q6       | Σ `fare_amount` / Σ `trip_distance`             | Líneas                         | Separa el precio de la distancia recorrida.                                                | `05_precio.sql`, `tablero/05b_*`                      |
| 6. Forma de pago                 | Q7       | % de viajes por forma de pago                   | Barras apiladas (una por tipo) | Muestra la composición de los pagos y su cambio en el tiempo.                              | `06_forma_pago.sql`, `tablero/06a_*`, `tablero/06b_*` |
| 7. Propina con tarjeta           | Q8       | Σ `tip_amount` / Σ `fare_amount` (solo tarjeta) | Líneas                         | Solo los pagos con tarjeta registran propina (Ejercicio 4).                                | `07_propina_tarjeta.sql`, `tablero/07_*`              |
| 8. Velocidad por hora            | Q9       | Σ distancia / Σ horas de viaje                  | Líneas                         | Usa la velocidad como medida de la congestión vial.                                        | `08_velocidad_por_hora.sql`, `tablero/08_*`           |
| 9. Recargos por congestión       | Q10      | (congestión + CBD) / total cobrado, en %        | Líneas                         | Cuantifica el peso de los recargos de congestión, incluido el CBD que se cobra desde 2025. | `09_recargos_congestion.sql`, `tablero/09_*`          |

Los archivos `NN_*.sql` están en `sql/07_indicadores/` y los `tablero/*` en `sql/07_indicadores/tablero/`.

### 7.8 Interpretación de los indicadores

1. **Viajes por día (Q1).**
   - Los amarillos tienen una estacionalidad clara: bajan en enero y en julio–agosto (92.6 mil y 92.7 mil por día en 2024) y suben en primavera y otoño (119.2 mil en octubre de 2024; 126.2 mil en mayo de 2026).
   - Los verdes bajan de 1,570–1,860 viajes por día en 2024 a 1,250–1,420 en 2026.
2. **Participación de verdes (Q2).** Los taxis verdes pasan del 1.83% de los viajes (enero de 2024) a entre 1.09% y 1.21% en 2026. Pierden participación de forma sostenida.
3. **Viajes por hora (Q3).**
   - Los verdes tienen un pico marcado a las 17:00 (8.08%) y caen rápido por la noche.
   - Los amarillos mantienen una demanda alta entre las 17:00 y las 22:00 (5.5–6.9%) y conservan actividad de madrugada (3.02% a medianoche).
4. **Día de la semana (Q4).**
   - Los verdes están por encima del promedio de martes a viernes (máximo el jueves, 112.9) y muy por debajo el fin de semana (domingo, 80.2).
   - Los amarillos tienen su máximo el jueves (109.8) y el sábado (108.4), y su mínimo el lunes (85.4).
5. **Total promedio (Q5).** El costo por viaje sube entre enero de 2024 y agosto de 2026: de 27.32 a 30.15 USD en amarillos (+10%) y de 22.25 a 26.51 USD en verdes (+19%).
6. **Tarifa por milla (Q6).**
   - En amarillos se mantiene entre 5.6 y 6.3 USD por milla.
   - En verdes baja de ~6.0–6.3 (2024) a ~4.8–5.3 (2026). Coincide con viajes verdes más largos en 2026 (distancia promedio de 2.95 a 3.36 millas, Ejercicio 5): los costos fijos se reparten entre más millas.
7. **Forma de pago (Q7).**
   - El **efectivo disminuye** en ambos tipos: de 12–15% a 8–10% en amarillos y de 25–30% a 18–21% en verdes.
   - En 2026 crece mucho la categoría *Flex Fare / sin dato*: de 4–13% a 20–29% en amarillos y de 3–6% a 13–16% en verdes. Por eso, en amarillos también baja el porcentaje de pagos con tarjeta.
8. **Propina con tarjeta (Q8).** Es estable: entre 20% y 23% de la tarifa base en ambos tipos, ligeramente mayor en amarillos.
9. **Velocidad por hora (Q9).**
   - El tráfico es más lento entre las 14:00 y las 18:00: ~10 mph en amarillos y ~8 mph en verdes.
   - A las 4:00–5:00 la velocidad se duplica en amarillos (19–20 mph).
10. **Recargos por congestión (Q10).**
    - Representan el 7–8% del total en amarillos y el 3–3.5% en verdes, porque los amarillos operan más en Manhattan, donde se aplican.
    - En 2026 el porcentaje no aumenta a pesar del nuevo cargo CBD. En parte, esto se debe a que los viajes *Flex Fare* no registran `congestion_surcharge` (Ejercicio 3) y cuentan como 0.

**Principales hallazgos:**

- **Divergencia entre servicios:** la demanda de taxis amarillos en 2026 supera a la de 2024 en los mismos meses, mientras que los verdes pierden viajes y participación.
- **Patrones de uso distintos:** los verdes responden a un uso diurno y laboral; los amarillos, a un uso extendido hacia la noche y el fin de semana.
- **Aumento del costo y menos efectivo:** el total por viaje sube en ambos tipos y el efectivo pierde peso.
- **La calidad de los datos afecta los indicadores:** el crecimiento de *Flex Fare / sin dato* en 2026 cambia la composición de pagos y subestima recargos y pasajeros. Los indicadores de 2026 que dependen de esas columnas deben interpretarse con cautela.

## Ejercicio 8

La descarga de 2025, la verificación de las consultas, la actualización de los indicadores, el análisis de la evolución y los cambios entre 2024, 2025 y 2026 (8.1–8.7) están documentados en `notebooks/08_analisis_completo.ipynb`. Las consultas nuevas están en `sql/08_analisis/`.

El tablero actualizado con los tres años se encuentra en `docs/tablero/tablero_2024_2025_2026.png`.

## Ejercicio 9 – Discusión

### 9.1 ¿Qué características de DuckDB resultaron más útiles durante el laboratorio?

- **Consulta directa de archivos Parquet** (`read_parquet`): permitió analizar más de 120 millones de registros sin un paso de carga ni un servidor de base de datos.
- **Patrones de archivos y `union_by_name`:** con `data/raw/<tipo>/*/*.parquet` se incorporaron 2024 y 2025 sin modificar las consultas, y `union_by_name` resolvió las columnas que aparecen o desaparecen entre años (`cbd_congestion_fee`, `request_source`). También permitió detectar que, sin esta opción, DuckDB descarta columnas en silencio.
- **Funciones sobre metadatos** (`glob`, `parquet_file_metadata`, `parquet_schema`): contar archivos y registros y comparar esquemas tomó menos de un segundo, sin leer los datos.
- **Vistas:** la vista `viajes` centralizó la unificación de amarillos y verdes y los filtros de calidad, y la reutilizaron más de 20 consultas.
- **Control de recursos** (`memory_limit`, `threads`): con 1 GB y 2 hilos, DuckDB procesó todo el conjunto en un equipo con 3 GB de RAM, usando el disco para resultados intermedios cuando hizo falta. Sin estos límites, las primeras consultas agotaron la memoria y congelaron el ambiente.
- **SQL analítico completo:** funciones de ventana, `FILTER`, `PIVOT`/`UNPIVOT`, `approx_quantile` y `SUMMARIZE` hicieron posible el EDA completo solo con SQL.
- **`ATTACH`:** permitió materializar tablas en otra base desde la misma conexión (benchmark y base del tablero).
- **Integración** con Python/pandas y con Metabase (driver DuckDB) sin cambiar de motor.

### 9.2 ¿Qué ventajas y limitaciones encontró al consultar directamente archivos Parquet?

**Ventajas:**

- Disponibilidad inmediata: los archivos se consultan en cuanto se descargan.
- Sin duplicar datos: los Parquet ocupan la mitad que la base DuckDB equivalente (1,172 MB frente a 2,293 MB).
- Lectura selectiva: solo se leen las columnas usadas, y los metadatos responden conteos y esquemas al instante.
- Flexibilidad: agregar un año solo requiere descargar los archivos.
- Formato abierto, legible por otras herramientas.

**Limitaciones:**

- Cada consulta repite la lectura, la descompresión, la unión de tipos de taxi y los filtros: en el benchmark fue 2.3–2.6 veces más lenta que la tabla (hasta 7 veces en agregaciones simples).
- El esquema puede cambiar entre archivos sin aviso. Hubo que usar `union_by_name` y tratar `cbd_congestion_fee` como 0 en 2024.
- Los archivos no se pueden modificar (`UPDATE`/`DELETE`). Las correcciones de calidad se aplican en cada consulta mediante la vista.
- El rendimiento depende de cómo está escrito el archivo (compresión, tamaño de los grupos de filas), algo que el analista no controla.

### 9.3 ¿Qué ventajas y limitaciones observó al utilizar tablas materializadas en DuckDB?

**Ventajas:**

- Consultas más rápidas en los 15 casos medidos (1.6–6.9 veces), porque las transformaciones se hacen una sola vez.
- Las repeticiones aprovechan el caché de DuckDB: la primera ejecución es más lenta y las siguientes, más rápidas.
- Permiten modificar datos y construir capas de datos preparados. Por ejemplo, las tablas pequeñas de indicadores hicieron el tablero de Metabase rápido y liviano.

**Limitaciones:**

- Costo de creación: 81 s para 69 millones de viajes. Solo conviene si el análisis se repite (se recupera tras unas dos ejecuciones del conjunto de consultas).
- Ocupan casi el doble de espacio que los Parquet y duplican los datos.
- Se desactualizan: al llegar 2025 hubo que reconstruir la base del tablero, mientras que las consultas sobre Parquet lo incluyeron solas.
- Concurrencia: un archivo `.duckdb` admite un solo proceso con escritura. Para reconstruir la base del tablero hubo que escribirla en un archivo temporal o detener Metabase.
- Si la base no cabe en la memoria asignada, la ventaja disminuye (de 6.9 a 4.1 veces en el volumen mayor).

### 9.4 ¿Qué ventajas ofrece este flujo frente a cargar todos los datos con Pandas?

- **Memoria:** pandas necesita cargar en RAM todas las filas y columnas usadas. Los ~120 millones de viajes amarillos, con 20 columnas, ocuparían decenas de GB, imposible con los 3 GB disponibles. DuckDB procesó todo con un límite de 1 GB porque trabaja por bloques y puede usar el disco.
- **Lectura selectiva:** DuckDB lee solo las columnas y grupos de filas necesarios; pandas normalmente carga el archivo completo.
- **Paralelismo y ejecución vectorizada:** DuckDB ejecuta las agregaciones en paralelo y por columnas, sin escribir ciclos en Python.
- **Reproducibilidad y documentación:** cada transformación queda escrita en archivos `.sql` versionables y reutilizables (notebooks, scripts, benchmark y Metabase).
- **Datos nuevos sin cambios:** los patrones de archivos incluyen los nuevos meses sin código adicional.
- **Combinación:** pandas sigue siendo útil para lo que hace bien. En este flujo solo recibe resultados pequeños, ya agregados por DuckDB, para tablas y gráficos.

### 9.5 ¿Qué características del sistema permiten incorporar nuevos datos con cambios mínimos?

- Script de descarga parametrizado por año (`--anio`) e idempotente (omite archivos existentes y detecta meses no publicados).
- Estructura fija `data/raw/<tipo>/<año>/` con los nombres originales de la TLC.
- Consultas con patrones de archivos (`*/*.parquet`) y `union_by_name`.
- Vista única `viajes` como punto central de transformación: el único ajuste por un año nuevo (`coalesce(cbd_congestion_fee, 0)`) se hizo en un solo archivo.
- Indicadores agregados por período y año, que se reconstruyen con un comando (`scripts/indicadores.py`).
- Tablero creado por script (`scripts/tablero_metabase.py`), que actualiza las preguntas existentes en lugar de duplicarlas.

Con este diseño, incorporar 2024 y 2025 no requirió cambiar ninguna consulta de análisis.

### 9.6 ¿Qué parte del proceso debería automatizarse en un sistema de producción?

- **Descarga programada:** ejecutar `download_data.py` periódicamente (por ejemplo, con un cron o un orquestador) para obtener los meses que la TLC publica con retraso.
- **Validación automática** de cada archivo nuevo: tamaño frente al servidor, lectura con DuckDB, número de registros y comparación del esquema con los meses anteriores. Debería alertar ante columnas nuevas o faltantes, como `cbd_congestion_fee` o `request_source`.
- **Monitoreo de calidad:** seguimiento mensual de los porcentajes de nulos, *Flex Fare*, montos negativos, etc., con alertas cuando cambian bruscamente (por ejemplo, *Flex Fare* pasó de 9% a 25%).
- **Reconstrucción de indicadores y del tablero** después de cada carga validada (`indicadores.py` + `tablero_metabase.py`), sin detener Metabase.
- **Ejecución de los notebooks o reportes** y de un benchmark periódico para detectar degradación del rendimiento.
- **Manejo de credenciales** mediante variables de entorno o un gestor de secretos, en lugar de valores por defecto.

### 9.7 ¿Qué decisiones de diseño fueron importantes para mantener el proyecto reproducible?

- **Ambiente en Docker** con versiones fijas (Python 3.11, DuckDB 1.5.5, Metabase y su driver alineados).
- **Datos fuera de Git** pero obtenibles con un script que usa la fuente oficial y es idempotente.
- **SQL en archivos** con comentarios de objetivo y fuente, separados del código que los ejecuta; los notebooks muestran el SQL antes de cada resultado.
- **Transformaciones explícitas en la vista** `viajes`, sin modificar los datos originales.
- **Rutas relativas a la raíz del proyecto** dentro de los scripts, para que funcionen desde cualquier directorio.
- **Configuración de recursos explícita** (`memory_limit`, `threads`) en notebooks y scripts, para que el análisis corra igual en equipos con poca memoria.
- **Resultados intermedios guardados** (CSV del benchmark) y **muestras con semilla** (`REPEATABLE (42)`).
- **Scripts de un solo comando** para cada etapa: descarga, benchmark, indicadores y tablero.
- **Volúmenes del benchmark fijados** por patrón de archivos (`202[46]`), para que incorporar años nuevos no altere la comparación documentada.

### 9.8 ¿Qué aprendió sobre el manejo de datos que no habría sido evidente con conjuntos pequeños?

- **Los recursos son una restricción real.** Consultas correctas congelaron el ambiente por falta de memoria. Hubo que limitar DuckDB, detener servicios y reemplazar percentiles exactos por aproximados. Con pocos datos nada de esto aparece.
- **El costo de cada decisión se multiplica.** Leer o no una columna, materializar o no una tabla, o usar un percentil exacto cambia el tiempo de segundos a minutos (por ejemplo, el perfil `SUMMARIZE` pasó de 50 s a ~5 min).
- **Los aproximados son una herramienta legítima**, aunque producen pequeñas variaciones entre ejecuciones que deben documentarse.
- **Los esquemas cambian con el tiempo.** Con decenas de archivos mensuales aparecen columnas nuevas, columnas que solo existen en algunos meses y cambios de significado. Hay que verificarlo explícitamente.
- **Los porcentajes pequeños son muchos registros.** Un 0.5% de montos negativos equivale a más de 150 mil viajes en 2026. La calidad debe medirse en proporciones y en conteos.
- **Las tendencias solo aparecen con varios años.** La caída de los taxis verdes, el aumento de *Flex Fare* y el inicio del cargo CBD no se distinguen de la estacionalidad con un solo mes o un solo año.
- **Hay que separar almacenamiento, procesamiento y presentación.** El tablero funcionó bien solo cuando consultó tablas agregadas pequeñas, no los datos crudos.
