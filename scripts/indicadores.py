#!/usr/bin/env python3
"""Construye la base DuckDB de indicadores usada por el tablero de Metabase.

Crea la vista `viajes` (sql/04_eda/00_vista_viajes.sql) sobre todos los archivos
Parquet de data/raw/ y ejecuta cada archivo de sql/07_indicadores/, que crea una
tabla agregada `ind_*` en la base destino.

La base se escribe en un archivo temporal y luego reemplaza a
data/processed/tablero.duckdb, de modo que una conexion de solo lectura abierta
(por ejemplo, Metabase) no bloquea la reconstruccion.

Uso:
    python scripts/indicadores.py
"""

import os
import time
from pathlib import Path

import duckdb

RAIZ = Path(__file__).resolve().parent.parent
SQL_VISTA = RAIZ / "sql/04_eda/00_vista_viajes.sql"
DIR_INDICADORES = RAIZ / "sql/07_indicadores"
DESTINO = RAIZ / "data/processed/tablero.duckdb"

CONFIG = {"memory_limit": "1GB", "threads": 2, "preserve_insertion_order": False}


def construir() -> None:
    """Crea todas las tablas de indicadores y publica la base en DESTINO."""
    os.chdir(RAIZ)  # las rutas de los SQL son relativas a la raiz del proyecto
    temporal = DESTINO.with_suffix(".duckdb.tmp")
    temporal.unlink(missing_ok=True)
    DESTINO.parent.mkdir(parents=True, exist_ok=True)

    con = duckdb.connect(config=CONFIG)
    con.execute(SQL_VISTA.read_text())
    con.execute(f"ATTACH '{temporal}' AS destino")
    for ruta in sorted(DIR_INDICADORES.glob("*.sql")):
        inicio = time.perf_counter()
        con.execute(ruta.read_text())
        print(f"{ruta.name:32s} {time.perf_counter() - inicio:6.1f} s", flush=True)

    tablas = con.execute(
        "SELECT table_name, estimated_size FROM duckdb_tables() "
        "WHERE database_name = 'destino' ORDER BY table_name"
    ).fetchall()
    con.execute("DETACH destino")
    con.close()

    os.replace(temporal, DESTINO)
    DESTINO.chmod(0o644)
    for nombre, filas in tablas:
        print(f"  {nombre:32s} {filas:6d} filas")
    print(f"Base de indicadores: {DESTINO}")


if __name__ == "__main__":
    construir()
