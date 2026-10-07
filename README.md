# Lab 8 - DuckDB

Repositorio base del laboratorio 8 del curso **CC3084 - Data Science**
(Universidad del Valle de Guatemala, Ciclo 2, 2026).

Este es el repositorio **proporcionado por el docente**. Contiene la estructura
del proyecto, el ambiente de ejecucion basado en Docker y un script que descarga
los datos de **2026**. Todo lo demas debe ser construido por cada equipo.

## Trabajo con fork

El laboratorio se desarrolla y se entrega sobre un **fork** de este repositorio.
No se trabaja directamente sobre el repositorio del docente.

1. Realice un fork de este repositorio:
   <https://github.com/menene/duckdb>

2. Clone **su propio fork** (no el del docente):

   ```bash
   git clone https://github.com/<su-usuario>/duckdb.git
   cd duckdb
   ```

3. Opcional, para recibir correcciones publicadas por el docente:

   ```bash
   git remote add upstream https://github.com/menene/duckdb.git
   git fetch upstream
   ```

Realice commits frecuentes y descriptivos: el historial del repositorio es parte
de la evaluacion. **La entrega del laboratorio es la URL de su fork.**

## Estructura

```text
duckdb/
|
+-- data/
|   +-- raw/
|   +-- processed/
|
+-- notebooks/
|
+-- scripts/
|
+-- sql/
|
+-- docs/
|
+-- Dockerfile
+-- metabase.Dockerfile
+-- docker-compose.yml
+-- README.md
```

## Requisitos

- Docker, con Docker Compose
- Git

La primera construccion del ambiente descarga varios cientos de MB y puede
tardar algunos minutos.

Considere el espacio en disco: las imagenes de Docker ocupan unos 3 GB y los
datos de los tres anios del laboratorio superan 1.5 GB, a los que se suma la
base materializada del Ejercicio 6. Se recomienda tener al menos 10 GB libres.

Memoria: los notebooks abren DuckDB con `memory_limit = 1GB` y `threads = 2`, de modo
que el analisis funciona en equipos con poca RAM (por ejemplo, WSL con 3 GB). Si la
memoria es limitada, detenga Metabase mientras no se utilice:

```bash
docker compose stop metabase    # detener
docker compose start metabase   # volver a iniciar
```

## Datos

El repositorio incluye `scripts/download_data.py`, que descarga los archivos de
2026 publicados por la TLC (`--help` muestra las opciones disponibles). Los
archivos se guardan en `data/raw/<tipo>/<anio>/`.

La TLC publica cada mes con varias semanas de atraso, por lo que los ultimos
meses de 2026 todavia no existen. El script consulta al servidor que meses estan
publicados, de modo que vuelve a ejecutarse sin problema conforme aparezcan
nuevos archivos.

Los datos descargados **no deben incluirse en el repositorio Git**. El archivo
`.gitignore` ya esta configurado para evitarlo.

Fuente de datos: NYC TLC Trip Record Data
<https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page>

Dentro de los contenedores, la carpeta `data/` del proyecto esta montada en
`/workspace/data`. Esa es la ruta que deben usar las herramientas que corren
dentro del ambiente, no la ruta de su computadora.

> **Nota sobre DuckDB:** un archivo `.duckdb` admite un solo proceso con permiso
> de escritura a la vez. Si conecta una herramienta externa a su base de datos,
> use el modo de solo lectura (`read_only`) en esa conexion; de lo contrario los
> demas procesos no podran abrir el archivo.

## Material a entregar

Al finalizar, su fork debe contener:

- el codigo fuente modificado y los scripts de descarga;
- las consultas SQL desarrolladas;
- el notebook o notebooks utilizados;
- la documentacion de las consultas;
- los scripts utilizados para los benchmarks;
- el codigo de los indicadores y visualizaciones;
- el tablero o la evidencia del tablero desarrollado;
- este `README.md`, completado segun la siguiente seccion.

Los archivos de datos descargados **no** deben incluirse.

---

# Documentacion del equipo

Las siguientes secciones deben ser completadas por cada equipo. El README final
debe permitir que una persona que no participo en el desarrollo pueda levantar el
ambiente, descargar los datos, ejecutar el analisis, reproducir los benchmarks y
generar los resultados principales.

## Como levantar el ambiente

1. Verificar que Docker este en ejecucion (`docker info`).
2. Desde la raiz del repositorio, construir y levantar los servicios en segundo
   plano:

   ```bash
   docker compose up --build -d
   ```

3. Verificar que ambos contenedores esten en estado `running`:

   ```bash
   docker compose ps
   ```

4. Verificar los servicios (Metabase tarda alrededor de un minuto en iniciar):

   | Servicio   | Contenedor      | URL                     | Verificacion                                                |
   | ---------- | --------------- | ----------------------- | ----------------------------------------------------------- |
   | JupyterLab | `lab8-lab`      | <http://localhost:8888> | `curl localhost:8888/api` devuelve la version               |
   | Metabase   | `lab8-metabase` | <http://localhost:3000> | `curl localhost:3000/api/health` devuelve `{"status":"ok"}` |

5. Ejecutar comandos dentro del ambiente de analisis:

   ```bash
   docker compose exec lab <comando>
   ```

6. Detener el ambiente (los datos y la configuracion de Metabase se conservan):

   ```bash
   docker compose down
   ```

Herramientas disponibles:

- `lab8-lab`: Python 3.11.14, DuckDB 1.5.5, JupyterLab 4.6.4, pandas 3.0.6,
  pyarrow 25.0.1, matplotlib 3.11.2, requests 2.34.2 y curl.
- `lab8-metabase`: Metabase v0.63.19 (Java 21) con el driver de DuckDB 1.5.5.0.

## Como descargar los datos

El script `scripts/download_data.py` descarga los archivos Parquet mensuales de
taxis amarillos y verdes en `data/raw/<tipo>/<año>/`.

```bash
# 2026 (por defecto), amarillos y verdes
docker compose exec lab python scripts/download_data.py

# un tipo de taxi o varios años
docker compose exec lab python scripts/download_data.py --taxi green
docker compose exec lab python scripts/download_data.py --anio 2024 2026
```

Datos utilizados en el laboratorio (Ejercicios 5 y 8):

```bash
docker compose exec lab python scripts/download_data.py --anio 2024 2025 2026
```

- Solo se descargan los meses publicados por la TLC; los demás se reportan como
  "no publicados".
- Los archivos que ya existen localmente se omiten, por lo que el script puede
  ejecutarse de nuevo para obtener meses publicados posteriormente.
- Al finalizar se imprime un resumen (descargados, ya existian, no publicados,
  fallidos). El codigo de salida es `1` si algun archivo fallo.

Cambios realizados al script original:

| Cambio                   | Detalle                                                                                                                                                                  |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Año parametrizable       | Se reemplazo la constante `ANIO = 2026` por el argumento `--anio` (uno o varios anios; por defecto `2026`).                                                              |
| Funciones con año        | `construir_nombre`, `construir_url`, `ruta_destino` y `descargar` reciben `anio` como parametro.                                                                         |
| Ciclo por año            | `main()` recorre cada anio y cada tipo de taxi, acumulando un unico resumen.                                                                                             |
| Ruta de destino absoluta | `DIR_DESTINO` se calcula a partir de la ubicacion del script, de modo que los archivos siempre quedan en `data/raw/` sin importar el directorio desde el que se ejecute. |
| Docstrings               | Se actualizaron para reflejar el soporte de varios anios.                                                                                                                |

## Como ejecutar el analisis

El analisis esta en `notebooks/` y usa las consultas SQL de `sql/`. Abra JupyterLab en
<http://localhost:8888> o ejecute un notebook completo desde la terminal:

```bash
docker compose exec lab jupyter nbconvert --to notebook --execute --inplace \
    --ExecutePreprocessor.timeout=2400 notebooks/<notebook>.ipynb
```

| Notebook                      | Ejercicio | Consultas               | Contenido                                                                                           |
| ----------------------------- | --------- | ----------------------- | --------------------------------------------------------------------------------------------------- |
| `03_exploracion.ipynb`        | 3         | `sql/03_exploracion/`   | Consultas directas sobre Parquet: archivos, registros, columnas, tipos, muestra y calidad de datos. |
| `04_eda.ipynb`                | 4         | `sql/04_eda/`           | Vista `viajes` (`00_vista_viajes.sql`), preguntas de analisis, graficos y hallazgos.                |
| `05_incorporacion_2024.ipynb` | 5         | `sql/05_incorporacion/` | Descarga de 2024, comparacion de esquemas y consulta conjunta.                                      |
| `06_benchmark.ipynb`          | 6         | `sql/06_benchmark/`     | Analisis del benchmark (lee `docs/benchmark/*.csv`).                                                |
| `08_analisis_completo.ipynb`  | 8         | `sql/08_analisis/`      | Descarga de 2025, verificacion de consultas y evolucion 2024-2026.                                  |

- Todas las consultas leen los Parquet con patrones (`data/raw/<tipo>/*/*.parquet`), por lo
  que incluyen todos los anios descargados. Los notebooks 03 a 05 documentan el conjunto de
  datos disponible en su etapa (2026; luego 2024 + 2026). Si se ejecutan con los tres anios
  descargados, sus resultados incluiran tambien 2025.
- Los notebooks abren DuckDB con `memory_limit = 1GB` y `threads = 2`. Los que recorren todos
  los viajes tardan varios minutos (el `08` tarda unos 15 minutos).
- Las respuestas a las preguntas que no estan en los notebooks se encuentran en
  `docs/respuestas.md`.

## Como reproducir los benchmarks

El script `scripts/benchmark.py` compara las mismas consultas de `sql/04_eda/` ejecutadas
directamente sobre los archivos Parquet y sobre una tabla DuckDB materializada, con tres
volumenes de datos (`1_mes`, `2026`, `2024_2026`). Requiere los datos de 2024 y 2026.

```bash
# crea las bases en data/processed/benchmark_<volumen>.duckdb y mide (unos 10-15 minutos)
docker compose exec lab python scripts/benchmark.py --recrear

# opciones
docker compose exec lab python scripts/benchmark.py --volumenes 1_mes 2026 --repeticiones 5
```

- Sin `--recrear`, las bases existentes se reutilizan y solo se repiten las mediciones.
- Resultados: `docs/benchmark/tiempos.csv` (cada repeticion) y
  `docs/benchmark/materializacion.csv` (tamano y tiempo de creacion de cada tabla).
- Analisis: `notebooks/06_benchmark.ipynb` (lee los CSV; no vuelve a ejecutar el benchmark).
- Las bases ocupan unos 3.4 GB en `data/processed/` (excluido de Git).

## Como generar los resultados principales

Secuencia completa, desde la raiz del repositorio:

```bash
# 1. Ambiente
docker compose up --build -d

# 2. Datos (2024, 2025 y 2026; omite archivos existentes)
docker compose exec lab python scripts/download_data.py --anio 2024 2025 2026

# 3. Analisis (Ejercicios 3, 4, 5 y 8)
for nb in 03_exploracion 04_eda 05_incorporacion_2024 08_analisis_completo; do
    docker compose exec lab jupyter nbconvert --to notebook --execute --inplace \
        --ExecutePreprocessor.timeout=2400 notebooks/$nb.ipynb
done

# 4. Benchmark (Ejercicio 6) y su analisis
docker compose exec lab python scripts/benchmark.py --recrear
docker compose exec lab jupyter nbconvert --to notebook --execute --inplace notebooks/06_benchmark.ipynb

# 5. Indicadores y tablero (Ejercicios 7 y 8)
docker compose stop metabase                         # libera data/processed/tablero.duckdb
docker compose exec lab python scripts/indicadores.py
docker compose start metabase
docker compose exec lab python scripts/tablero_metabase.py
```

Paso 5:

- `scripts/indicadores.py` crea `data/processed/tablero.duckdb` con las tablas `ind_*` definidas
  en `sql/07_indicadores/`.
- `scripts/tablero_metabase.py` configura Metabase por su API: crea el usuario administrador,
  la conexion DuckDB de solo lectura, una pregunta por cada consulta de
  `sql/07_indicadores/tablero/` y el tablero "Viajes de taxi NYC - Indicadores". Si se ejecuta
  de nuevo, actualiza lo existente.
- Acceso al tablero: <http://localhost:3000> con `admin@lab8.local` / `Lab8-DuckDB-2026`
  (credenciales locales por defecto; se pueden cambiar con las variables `MB_EMAIL` y
  `MB_PASSWORD`).
- Evidencia: `docs/tablero/tablero_2024_2026.png` (Ejercicio 7) y
  `docs/tablero/tablero_2024_2025_2026.png` (Ejercicio 8).

Resultados y documentacion:

| Resultado                               | Ubicacion            |
| --------------------------------------- | -------------------- |
| Consultas SQL documentadas              | `sql/`               |
| Notebooks ejecutados                    | `notebooks/`         |
| Tiempos del benchmark                   | `docs/benchmark/`    |
| Capturas del tablero                    | `docs/tablero/`      |
| Respuestas y discusion (Ejercicios 1-9) | `docs/respuestas.md` |
