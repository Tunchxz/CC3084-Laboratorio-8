#!/usr/bin/env python3
"""Crea o actualiza el tablero de indicadores en Metabase mediante su API REST.

Pasos:
  1. Configuracion inicial de Metabase (usuario administrador), si aun no existe.
  2. Conexion DuckDB de solo lectura a data/processed/tablero.duckdb.
  3. Una pregunta SQL nativa por cada archivo de sql/07_indicadores/tablero/.
  4. Tablero "Viajes de taxi NYC - Indicadores" con todas las preguntas.

Las preguntas y el tablero se identifican por nombre: si ya existen se actualizan.
Requiere haber ejecutado antes scripts/indicadores.py.

Uso (dentro del contenedor `lab`):
    python scripts/tablero_metabase.py

Variables de entorno (opcionales):
    MB_URL       URL de Metabase (por defecto: http://metabase:3000)
    MB_EMAIL     correo del administrador (por defecto: admin@lab8.local)
    MB_PASSWORD  contrasena del administrador (por defecto: Lab8-DuckDB-2026)
"""

import os
from pathlib import Path

import requests

RAIZ = Path(__file__).resolve().parent.parent
DIR_SQL = RAIZ / "sql/07_indicadores/tablero"

URL = os.environ.get("MB_URL", "http://metabase:3000")
EMAIL = os.environ.get("MB_EMAIL", "admin@lab8.local")
PASSWORD = os.environ.get("MB_PASSWORD", "Lab8-DuckDB-2026")

NOMBRE_BASE = "Lab8 - Indicadores DuckDB"
ARCHIVO_BASE = "/workspace/data/processed/tablero.duckdb"  # ruta dentro del contenedor de Metabase
NOMBRE_TABLERO = "Viajes de taxi NYC - Indicadores"

COLORES_TIPO = {"yellow": "#E0A800", "green": "#2E8B57"}


def linea(x: str, serie: str | None, y: str, titulo_y: str, eje_derecho: str | None = None) -> dict:
    """Configuracion de una grafica de lineas de Metabase."""
    ajustes = {
        "graph.dimensions": [x, serie] if serie else [x],
        "graph.metrics": [y],
        "graph.x_axis.scale": "ordinal",
        "graph.y_axis.title_text": titulo_y,
        "graph.show_values": False,
    }
    if serie == "tipo":
        ajustes["series_settings"] = {t: {"color": c} for t, c in COLORES_TIPO.items()}
        if eje_derecho:
            ajustes["series_settings"][eje_derecho]["axis"] = "right"
    return ajustes


def barras(x: str, serie: str, y: str, titulo_y: str, apiladas: bool = False) -> dict:
    """Configuracion de una grafica de barras de Metabase."""
    ajustes = {
        "graph.dimensions": [x, serie],
        "graph.metrics": [y],
        "graph.x_axis.scale": "ordinal",
        "graph.y_axis.title_text": titulo_y,
    }
    if apiladas:
        ajustes["stackable.stack_type"] = "stacked"
    if serie == "tipo":
        ajustes["series_settings"] = {t: {"color": c} for t, c in COLORES_TIPO.items()}
    return ajustes


# (archivo SQL, titulo, pregunta que responde, tipo de grafica, ajustes)
TARJETAS = [
    ("01_viajes_por_dia.sql", "1. Viajes promedio por dia",
     "Q1. Como evoluciona la demanda de viajes mes a mes? (green en el eje derecho)",
     "line", linea("periodo", "tipo", "viajes_por_dia", "Viajes por dia", eje_derecho="green")),
    ("02_participacion_verdes.sql", "2. Participacion de taxis verdes (%)",
     "Q2. Que proporcion de los viajes realizan los taxis verdes y como cambia?",
     "line", linea("periodo", None, "pct_green", "% de viajes")),
    ("03_viajes_por_hora.sql", "3. Viajes por hora de inicio (%)",
     "Q3. En que horas se concentra la demanda?",
     "line", linea("hora", "serie", "pct_viajes", "% de viajes del tipo y anio")),
    ("04_viajes_por_dia_semana.sql", "4. Viajes por dia de la semana (indice, 100 = promedio)",
     "Q4. Que dias de la semana tienen mas viajes?",
     "bar", barras("dia", "serie", "indice", "Indice")),
    ("05a_total_promedio.sql", "5a. Total promedio por viaje (USD)",
     "Q5. Cuanto paga en promedio un pasajero por viaje y como cambia?",
     "line", linea("periodo", "tipo", "total_promedio", "USD")),
    ("05b_tarifa_por_milla.sql", "5b. Tarifa base por milla (USD)",
     "Q6. Cual es la tarifa base por milla y como cambia?",
     "line", linea("periodo", "tipo", "tarifa_por_milla", "USD por milla")),
    ("06a_forma_pago_yellow.sql", "6a. Forma de pago - taxis amarillos (%)",
     "Q7. Que formas de pago predominan y disminuye el uso de efectivo?",
     "bar", barras("periodo", "forma_pago", "pct_viajes", "% de viajes", apiladas=True)),
    ("06b_forma_pago_green.sql", "6b. Forma de pago - taxis verdes (%)",
     "Q7. Que formas de pago predominan y disminuye el uso de efectivo?",
     "bar", barras("periodo", "forma_pago", "pct_viajes", "% de viajes", apiladas=True)),
    ("07_propina_tarjeta.sql", "7. Propina con tarjeta (% de la tarifa)",
     "Q8. Que porcentaje de propina dejan los pasajeros que pagan con tarjeta?",
     "line", linea("periodo", "tipo", "pct_propina", "% de la tarifa")),
    ("08_velocidad_por_hora.sql", "8. Velocidad promedio por hora (mph)",
     "Q9. En que horas el trafico es mas lento?",
     "line", linea("hora", "serie", "velocidad_mph", "Millas por hora")),
    ("09_recargos_congestion.sql", "9. Recargos por congestion (% del total)",
     "Q10. Cuanto aportan los recargos por congestion al costo del viaje?",
     "line", linea("periodo", "tipo", "pct_del_total", "% del total cobrado")),
]

ANCHO, ALTO = 12, 7  # tamaño de cada tarjeta en la cuadricula de 24 columnas


class Metabase:
    """Cliente minimo de la API REST de Metabase."""

    def __init__(self, url: str) -> None:
        self.url = url.rstrip("/")
        self.sesion = requests.Session()

    def llamar(self, metodo: str, ruta: str, **kwargs) -> dict | list:
        """Ejecuta una peticion a /api/<ruta> y devuelve el JSON de respuesta."""
        respuesta = self.sesion.request(metodo, f"{self.url}/api/{ruta}", timeout=120, **kwargs)
        if not respuesta.ok:
            raise RuntimeError(f"{metodo} /api/{ruta} -> {respuesta.status_code}: {respuesta.text[:500]}")
        return respuesta.json() if respuesta.content else {}

    def iniciar_sesion(self) -> None:
        """Realiza la configuracion inicial si hace falta e inicia sesion."""
        propiedades = self.llamar("GET", "session/properties")
        if not propiedades.get("has-user-setup"):
            self.llamar("POST", "setup", json={
                "token": propiedades["setup-token"],
                "user": {"email": EMAIL, "password": PASSWORD, "first_name": "Lab8",
                         "last_name": "Admin", "site_name": "Lab 8 DuckDB"},
                "prefs": {"site_name": "Lab 8 DuckDB", "site_locale": "es", "allow_tracking": False},
            })
            print("Configuracion inicial de Metabase completada")
        token = self.llamar("POST", "session", json={"username": EMAIL, "password": PASSWORD})["id"]
        self.sesion.headers["X-Metabase-Session"] = token

    def base_de_datos(self) -> int:
        """Devuelve el id de la conexion DuckDB del tablero, creandola si no existe."""
        detalles = {"database_file": ARCHIVO_BASE, "read_only": True, "memory_limit": "256MB"}
        existentes = self.llamar("GET", "database")
        existentes = existentes.get("data", existentes) if isinstance(existentes, dict) else existentes
        for base in existentes:
            if base["name"] == NOMBRE_BASE:
                self.llamar("PUT", f"database/{base['id']}", json={"details": detalles})
                self.llamar("POST", f"database/{base['id']}/sync_schema")
                return base["id"]
        base = self.llamar("POST", "database", json={"engine": "duckdb", "name": NOMBRE_BASE, "details": detalles})
        print(f"Conexion creada: {NOMBRE_BASE} (id {base['id']})")
        return base["id"]

    def tarjeta(self, id_base: int, archivo: str, titulo: str, descripcion: str,
                grafica: str, ajustes: dict) -> int:
        """Crea o actualiza una pregunta SQL nativa; devuelve su id."""
        cuerpo = {
            "name": titulo,
            "description": f"{descripcion} Consulta: sql/07_indicadores/tablero/{archivo}",
            "display": grafica,
            "visualization_settings": ajustes,
            "dataset_query": {"type": "native", "database": id_base,
                              "native": {"query": (DIR_SQL / archivo).read_text()}},
        }
        for existente in self.llamar("GET", "card"):
            if existente["name"] == titulo and not existente.get("archived"):
                self.llamar("PUT", f"card/{existente['id']}", json=cuerpo)
                return existente["id"]
        return self.llamar("POST", "card", json=cuerpo)["id"]

    def tablero(self, ids_tarjetas: list[int]) -> int:
        """Crea o actualiza el tablero con las tarjetas en una cuadricula de 2 columnas."""
        id_tablero = next((t["id"] for t in self.llamar("GET", "dashboard")
                           if t["name"] == NOMBRE_TABLERO and not t.get("archived")), None)
        if id_tablero is None:
            id_tablero = self.llamar("POST", "dashboard", json={
                "name": NOMBRE_TABLERO,
                "description": "Indicadores de viajes de taxis amarillos y verdes (NYC TLC) calculados con DuckDB.",
            })["id"]
        tarjetas = [
            {"id": -(i + 1), "card_id": id_tarjeta, "row": (i // 2) * ALTO, "col": (i % 2) * ANCHO,
             "size_x": ANCHO, "size_y": ALTO, "parameter_mappings": [], "visualization_settings": {}}
            for i, id_tarjeta in enumerate(ids_tarjetas)
        ]
        self.llamar("PUT", f"dashboard/{id_tablero}", json={"dashcards": tarjetas})
        return id_tablero


def main() -> None:
    metabase = Metabase(URL)
    metabase.iniciar_sesion()
    id_base = metabase.base_de_datos()
    ids = [metabase.tarjeta(id_base, *definicion) for definicion in TARJETAS]
    print(f"Preguntas creadas o actualizadas: {len(ids)}")
    id_tablero = metabase.tablero(ids)
    print(f"Tablero: http://localhost:3000/dashboard/{id_tablero}")


if __name__ == "__main__":
    main()
