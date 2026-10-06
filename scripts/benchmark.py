#!/usr/bin/env python3
"""Compara el tiempo de consultas sobre archivos Parquet y sobre tablas DuckDB.

Para cada volumen de datos:
  1. Crea (si no existe) una base DuckDB en data/processed/benchmark_<volumen>.duckdb
     con la tabla `viajes`, materializada desde la vista sql/04_eda/00_vista_viajes.sql
     restringida a los archivos del volumen (sql/06_benchmark/crear_tabla.sql).
  2. Ejecuta las mismas consultas de sql/04_eda/ con dos estrategias:
       - parquet: `viajes` es la vista que lee los archivos Parquet en cada consulta;
       - tabla:   `viajes` es la tabla materializada (conexion de solo lectura).
  3. Registra el tiempo de cada repeticion.

Uso:
    python scripts/benchmark.py                          # todos los volumenes, 3 repeticiones
    python scripts/benchmark.py --volumenes 1_mes 2026
    python scripts/benchmark.py --repeticiones 5 --recrear

Salidas (CSV):
    docs/benchmark/tiempos.csv          volumen, consulta, estrategia, repeticion, segundos, filas
    docs/benchmark/materializacion.csv  volumen, archivos, bytes_parquet, registros,
                                        segundos_creacion, bytes_duckdb
"""

import argparse
import csv
import glob
import os
import time
from pathlib import Path

import duckdb

RAIZ = Path(__file__).resolve().parent.parent
SQL_VISTA = RAIZ / "sql/04_eda/00_vista_viajes.sql"
SQL_TABLA = RAIZ / "sql/06_benchmark/crear_tabla.sql"
DIR_BASES = RAIZ / "data/processed"
DIR_SALIDA = RAIZ / "docs/benchmark"

# Patron de archivos (relativo a data/raw/<tipo>/) que define cada volumen de datos
VOLUMENES = {
    "1_mes": "2026/*_2026-01.parquet",
    "2026": "2026/*.parquet",
    "2024_2026": "202[46]/*.parquet",
}

CONSULTAS = [
    "sql/04_eda/02_viajes_por_mes.sql",
    "sql/04_eda/03_viajes_hora_dia.sql",
    "sql/04_eda/04_caracteristicas_viaje.sql",
    "sql/04_eda/06_forma_pago.sql",
    "sql/04_eda/09_atipicos.sql",
]

CONFIG = {"memory_limit": "1GB", "threads": 2, "preserve_insertion_order": False}


def sql_vista(volumen: str) -> str:
    """Devuelve el SQL de la vista `viajes` restringido a los archivos de `volumen`."""
    sql = SQL_VISTA.read_text()
    for tipo in ("yellow", "green"):
        original = f"'data/raw/{tipo}/*/*.parquet'"
        if original not in sql:
            raise ValueError(f"no se encontro {original} en {SQL_VISTA}")
        sql = sql.replace(original, f"'data/raw/{tipo}/{VOLUMENES[volumen]}'")
    return sql


def archivos_volumen(volumen: str) -> list[str]:
    """Lista los archivos Parquet que forman parte de `volumen`."""
    return sorted(
        f for tipo in ("yellow", "green")
        for f in glob.glob(str(RAIZ / "data/raw" / tipo / VOLUMENES[volumen]))
    )


def conexion_parquet(volumen: str) -> duckdb.DuckDBPyConnection:
    """Conexion en memoria donde `viajes` es la vista sobre los Parquet del volumen."""
    con = duckdb.connect(config=CONFIG)
    con.execute(sql_vista(volumen))
    return con


def ruta_base(volumen: str) -> Path:
    """Ruta de la base DuckDB materializada del volumen."""
    return DIR_BASES / f"benchmark_{volumen}.duckdb"


def materializar(volumen: str, recrear: bool) -> dict | None:
    """Crea la tabla `viajes` del volumen; devuelve sus metricas o None si ya existia."""
    destino = ruta_base(volumen)
    if destino.exists() and not recrear:
        print(f"[{volumen}] base existente, se reutiliza: {destino}")
        return None
    destino.unlink(missing_ok=True)
    destino.parent.mkdir(parents=True, exist_ok=True)

    con = conexion_parquet(volumen)
    con.execute(f"ATTACH '{destino}' AS destino")
    inicio = time.perf_counter()
    con.execute(SQL_TABLA.read_text())
    con.execute("CHECKPOINT destino")
    segundos = time.perf_counter() - inicio
    registros = con.execute("SELECT count(*) FROM destino.viajes").fetchone()[0]
    con.close()

    archivos = archivos_volumen(volumen)
    metricas = {
        "volumen": volumen,
        "archivos": len(archivos),
        "bytes_parquet": sum(Path(f).stat().st_size for f in archivos),
        "registros": registros,
        "segundos_creacion": round(segundos, 2),
        "bytes_duckdb": destino.stat().st_size,
    }
    print(f"[{volumen}] tabla creada: {registros:,} registros en {segundos:.1f} s")
    return metricas


def medir(con: duckdb.DuckDBPyConnection, sql: str) -> tuple[float, int]:
    """Ejecuta `sql` completamente; devuelve (segundos, filas del resultado)."""
    inicio = time.perf_counter()
    filas = len(con.execute(sql).fetchall())
    return time.perf_counter() - inicio, filas


def ejecutar(volumenes: list[str], repeticiones: int) -> list[dict]:
    """Mide cada consulta con ambas estrategias en cada volumen."""
    registros = []
    for volumen in volumenes:
        conexiones = {
            "parquet": conexion_parquet(volumen),
            "tabla": duckdb.connect(str(ruta_base(volumen)), read_only=True, config=CONFIG),
        }
        for consulta in CONSULTAS:
            sql = (RAIZ / consulta).read_text()
            for estrategia, con in conexiones.items():
                for repeticion in range(1, repeticiones + 1):
                    segundos, filas = medir(con, sql)
                    registros.append({
                        "volumen": volumen,
                        "consulta": Path(consulta).stem,
                        "estrategia": estrategia,
                        "repeticion": repeticion,
                        "segundos": round(segundos, 4),
                        "filas": filas,
                    })
                    print(f"[{volumen}] {Path(consulta).stem:28s} {estrategia:7s} "
                          f"rep {repeticion}: {segundos:7.2f} s", flush=True)
        for con in conexiones.values():
            con.close()
    return registros


def escribir_csv(ruta: Path, filas: list[dict], anexar: bool = False) -> None:
    """Escribe `filas` en `ruta`; con `anexar`, reemplaza solo los volumenes presentes."""
    if not filas:
        return
    ruta.parent.mkdir(parents=True, exist_ok=True)
    previas = []
    if anexar and ruta.exists():
        volumenes = {f["volumen"] for f in filas}
        with ruta.open(newline="") as archivo:
            previas = [f for f in csv.DictReader(archivo) if f["volumen"] not in volumenes]
    with ruta.open("w", newline="") as archivo:
        escritor = csv.DictWriter(archivo, fieldnames=list(filas[0]))
        escritor.writeheader()
        escritor.writerows(previas + filas)


def main() -> None:
    parser = argparse.ArgumentParser(description="Benchmark Parquet vs tabla DuckDB.")
    parser.add_argument("--volumenes", nargs="+", choices=list(VOLUMENES), default=list(VOLUMENES),
                        help="volumenes de datos a evaluar (por defecto: todos)")
    parser.add_argument("--repeticiones", type=int, default=3,
                        help="repeticiones por consulta y estrategia (por defecto: 3)")
    parser.add_argument("--recrear", action="store_true",
                        help="vuelve a crear las bases DuckDB aunque ya existan")
    argumentos = parser.parse_args()

    os.chdir(RAIZ)  # las rutas de los SQL son relativas a la raiz del proyecto
    materializacion = [m for v in argumentos.volumenes if (m := materializar(v, argumentos.recrear))]
    escribir_csv(DIR_SALIDA / "materializacion.csv", materializacion, anexar=True)

    tiempos = ejecutar(argumentos.volumenes, argumentos.repeticiones)
    escribir_csv(DIR_SALIDA / "tiempos.csv", tiempos, anexar=True)
    print(f"Resultados en {DIR_SALIDA}")


if __name__ == "__main__":
    main()
