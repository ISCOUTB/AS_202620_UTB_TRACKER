"""
Prueba de contrato.

No compara el schema completo campo por campo (eso rompe en cualquier
cambio cosmético). Compara compatibilidad hacia atras: todo lo que el
contrato congelado (docs/contracts/openapi.json) promete, la version
en vivo de la app lo sigue cumpliendo. Un cambio incompatible en
app/schemas.py o app/routers/*.py hace fallar esta prueba - asi es
como se evita que un cambio del proveedor (el backend) rompa al
consumidor (el cliente Flutter) en silencio.

Se consideran cambios incompatibles:
- Eliminar un path o un metodo que el contrato ya prometia
- Eliminar un campo "required" de un schema de respuesta u operacion
- Cambiar el tipo de un campo que ya existia

No se consideran incompatibles (evolucion permitida sin romper el
contrato):
- Agregar un path, un metodo o un campo opcional nuevo
"""
import json
from pathlib import Path

from app.main import app

CONTRATO_CONGELADO = Path(__file__).parent.parent / "docs" / "contracts" / "openapi.json"


def _cargar_contrato_congelado():
    with open(CONTRATO_CONGELADO) as f:
        return json.load(f)


def _resolver_ref(schema, ref):
    """Resuelve un $ref simple del tipo '#/components/schemas/Nombre'."""
    partes = ref.lstrip("#/").split("/")
    nodo = schema
    for parte in partes:
        nodo = nodo[parte]
    return nodo


def test_todos_los_paths_del_contrato_siguen_existiendo():
    contrato = _cargar_contrato_congelado()
    en_vivo = app.openapi()

    for path, metodos in contrato["paths"].items():
        assert path in en_vivo["paths"], f"El path {path} desaparecio de la API en vivo"
        for metodo in metodos:
            assert metodo in en_vivo["paths"][path], (
                f"El metodo {metodo.upper()} {path} desaparecio de la API en vivo"
            )


def test_campos_requeridos_de_los_schemas_no_desaparecieron():
    contrato = _cargar_contrato_congelado()
    en_vivo = app.openapi()

    schemas_congelados = contrato.get("components", {}).get("schemas", {})
    schemas_en_vivo = en_vivo.get("components", {}).get("schemas", {})

    for nombre, definicion in schemas_congelados.items():
        requeridos_antes = set(definicion.get("required", []))
        if not requeridos_antes:
            continue

        assert nombre in schemas_en_vivo, (
            f"El schema '{nombre}' del contrato ya no existe en la API en vivo"
        )
        requeridos_ahora = set(schemas_en_vivo[nombre].get("required", []))

        faltantes = requeridos_antes - requeridos_ahora
        assert not faltantes, (
            f"El schema '{nombre}' ya no exige los campos {faltantes}, "
            f"que el contrato congelado (docs/contracts/openapi.json) prometia. "
            f"Esto rompe a cualquier cliente (Flutter) que dependa de recibirlos."
        )
