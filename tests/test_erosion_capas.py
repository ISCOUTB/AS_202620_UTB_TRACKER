"""
Control de erosión arquitectónica (S09, ADR-0001, arc42 §8.1).

Las reglas de capas se COMPRUEBAN en cada prueba y en el CI, no solo se documentan. Si alguien
(una persona o una IA) rompe una capa, esta prueba falla y dice qué archivo y qué línea.

Backend (4 capas, la dependencia apunta hacia abajo):
    routers -> services -> schemas / models -> core
- Un router no toca la base: no importa `app.models` ni hace consultas (`db.query`).
- Un servicio no conoce HTTP de rutas: no importa `app.routers`.
- Los modelos no dependen de schemas, servicios ni routers.
- `core` no depende de routers ni de servicios.

App Flutter (Clean Architecture del Blueprint del curso, la dependencia apunta al centro):
- `domain/` es Dart puro: no importa Flutter, `http`, ni las capas `data/` o `presentation/`.
- `data/` no importa `presentation/`.
"""
import re
from pathlib import Path

import pytest

RAIZ = Path(__file__).resolve().parent.parent
APP = RAIZ / "app"
FEATURES = RAIZ / "frontend" / "lib" / "features"

_IMPORT_PY = re.compile(r"^\s*(?:from|import)\s+(app(?:\.[\w]+)+)", re.M)
_IMPORT_DART = re.compile(r"^import\s+'([^']+)'", re.M)


def _imports_py(archivo: Path) -> list[tuple[int, str]]:
    texto = archivo.read_text(encoding="utf-8")
    return [(texto[: m.start()].count("\n") + 1, m.group(1)) for m in _IMPORT_PY.finditer(texto)]


def _violaciones_py(carpeta: str, prohibidos: tuple[str, ...]) -> list[str]:
    malas = []
    for archivo in sorted((APP / carpeta).glob("*.py")):
        for linea, modulo in _imports_py(archivo):
            if modulo.startswith(prohibidos):
                malas.append(f"{archivo.relative_to(RAIZ)}:{linea} importa {modulo}")
    return malas


@pytest.mark.parametrize("carpeta,prohibidos", [
    ("routers", ("app.models",)),
    ("services", ("app.routers",)),
    ("models", ("app.schemas", "app.services", "app.routers")),
    ("core", ("app.routers", "app.services")),
])
def test_backend_respeta_las_capas(carpeta, prohibidos):
    malas = _violaciones_py(carpeta, prohibidos)
    assert not malas, "Erosión de capas:\n" + "\n".join(malas)


def test_los_routers_no_consultan_la_base():
    malas = []
    for archivo in sorted((APP / "routers").glob("*.py")):
        for n, linea in enumerate(archivo.read_text(encoding="utf-8").splitlines(), 1):
            if re.search(r"\bdb\.(query|add|execute|commit|delete)\(", linea):
                malas.append(f"{archivo.relative_to(RAIZ)}:{n}: {linea.strip()}")
    assert not malas, "Un router hace trabajo de servicio:\n" + "\n".join(malas)


def _violaciones_dart(capa: str, prohibido) -> list[str]:
    malas = []
    for archivo in sorted(FEATURES.glob(f"*/{capa}/**/*.dart")):
        texto = archivo.read_text(encoding="utf-8")
        for m in _IMPORT_DART.finditer(texto):
            if prohibido(m.group(1)):
                linea = texto[: m.start()].count("\n") + 1
                malas.append(f"{archivo.relative_to(RAIZ)}:{linea} importa {m.group(1)}")
    return malas


def test_flutter_domain_es_dart_puro():
    malas = _violaciones_dart("domain", lambda u: (
        u.startswith("package:flutter/") or u.startswith("package:http/")
        or "/data/" in u or "/presentation/" in u or u.startswith("../data/")
        or u.startswith("../presentation/")))
    assert not malas, "domain/ debe ser Dart puro:\n" + "\n".join(malas)


def test_flutter_data_no_conoce_la_presentacion():
    malas = _violaciones_dart("data", lambda u: "/presentation/" in u or u.startswith("../presentation/"))
    assert not malas, "data/ no puede importar presentation/:\n" + "\n".join(malas)
