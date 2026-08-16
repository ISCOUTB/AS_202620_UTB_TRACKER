# Aspectos — Tractar

Un aspecto es un corte vertical del sistema con valor propio, trazable de punta a punta:

```
aspecto → requisito → elementos C4 → ADR → código → pruebas → evidencia de calidad
```

Cada fila de la tabla debe poder recorrerse completa. En esta entrega varias
columnas quedan en `—` porque todavía no existen ADRs, código ni pruebas.

## A-01 · Declarar

- **Nombre:** Formularios intuitivos para conductores y propietarios
- **Para quién:** Conductores con conocimiento tecnológico limitado y propietarios, algunos de
  la tercera edad, que hoy dependen del registro en papel.
- **Qué problema resuelve:** El registro manual de viajes es lento y se pierde si el conductor
  se desvincula antes de entregar la información. Si el reemplazo digital no es igual de
  simple que el papel, no hay adopción y el problema no se resuelve de verdad.

## Tabla de trazabilidad

| ID | Aspecto | Requisito | C4 | ADR | Código | Pruebas | Evidencia |
|----|---------|-----------|----|----|--------|---------|-----------|
| A-01 | Formularios intuitivos para conductores y propietarios | Usabilidad para usuarios con poca experiencia tecnológica | C1: Usuario ↔ Tu sistema (definido, S2) — C2/C3: pendiente (S4, S6) | — pendiente, se anota si aplica | — | — | — |

## Especificar (pendiente de escenario medible)

Falta redactar el escenario de calidad en formato de seis partes (estímulo, fuente, entorno,
artefacto, respuesta, medida) para A-01. Se completa cuando trabajemos la sección 10
(Requisitos de calidad) del arc42.
