# Evidencia: la prueba de contrato falla ante un cambio incompatible

Demostración hecha el 31/08/2026, quitando el campo `serial` (obligatorio) de la respuesta
`RecursoOut` en `app/schemas.py`, sin tocar el contrato congelado
(`docs/contracts/openapi.json`).

## Con el cambio incompatible presente

```
$ pytest tests/test_contract.py -v

FAILED tests/test_contract.py::test_campos_requeridos_de_los_schemas_no_desaparecieron
AssertionError: El schema 'RecursoOut' ya no exige los campos {'serial'}, que el contrato
congelado (docs/contracts/openapi.json) prometia. Esto rompe a cualquier cliente (Flutter)
que dependa de recibirlos.
```

## Después de revertir el cambio

```
$ pytest tests/ -v

======================== 9 passed, 4 warnings in 0.10s =========================
```

## Por qué esto demuestra que la prueba cumple su función

La prueba no compara texto contra texto — compara **promesas del contrato contra lo que la
API expone en vivo**. Agregar un campo nuevo (evolución compatible) no la rompe; quitar un
campo que ya era obligatorio, sí. Esa es la diferencia entre una prueba de contrato real y una
que solo verifica "algo cambió".
