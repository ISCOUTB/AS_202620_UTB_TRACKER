# 0001 - Estilo arquitectónico: Monolito Modular

## Estado

Aceptado

## Contexto

UTB Tracker tiene que construirse en un semestre académico con un equipo de 4 personas
que además cursan otras materias (restricción organizacional, sección 2.2 de arc42).
El stack fue migrado de Django a **FastAPI + Flutter** en la Semana 4 (ver ADR-0002),
y el sistema atiende a auxiliares de planta y usuarios UTB de la universidad (profesores,
estudiantes) para el registro de préstamos de equipos electrónicos de salones y
laboratorios.

Los escenarios de calidad que más presionan esta decisión son:
- **QS-03 (concurrencia):** el sistema debe soportar hasta 300 usuarios simultáneos en
  hora pico del campus sin degradar el servicio.
- **QS-06 (confiabilidad de datos):** ningún equipo puede quedar prestado dos veces al
  mismo tiempo — la regla de negocio central del sistema.

Este ADR corresponde a los aspectos **A-02** (disponibilidad), **A-04** (concurrencia)
y de forma transversal a todos los declarados en `docs/aspectos.md`, porque la decisión
de estilo arquitectónico afecta la estructura completa del código, no un solo módulo.

## Decisión

Se organiza UTB Tracker como un **Monolito Modular** sobre FastAPI: un único desplegable,
dividido internamente en módulos de dominio independientes (`app/routers/resources.py`,
`app/routers/loans.py`, `app/routers/auth.py`), cada uno con su propia frontera de
responsabilidad.

## Alternativas consideradas

**Capas (N-tier).**
Se descartó porque el acoplamiento técnico entre capas dificulta que el equipo trabaje en
paralelo: un cambio en la lógica de préstamos tocaría simultáneamente la capa de
presentación, la de negocio y la de persistencia.

**Hexagonal (puertos y adaptadores).**
Se descartó por costo/tiempo, no por ser mala idea en abstracto. El equipo son 4
estudiantes con un semestre y sin experiencia previa sosteniendo puertos y adaptadores
bajo presión de entrega; el riesgo real es que la abstracción se rompa a mitad de camino
y termine costando más de lo que aporta. Ver matriz completa en `docs/matriz_estilos.md`.

## Consecuencias

**Se gana:** cada módulo de dominio puede evolucionar con bajo choque entre los 4
integrantes (uno puede trabajar en `routers/loans.py` mientras otro trabaja en
`routers/resources.py` sin pisarse), y el estilo no pelea con FastAPI, que ya está
pensado para organizarse en routers independientes.

**Se asume:** el monolito modular solo funciona si el equipo respeta la frontera entre
módulos (por ejemplo, que `loans` no importe directamente el ORM interno de `auth`).
Esa disciplina no la impone el framework; la sostiene el equipo en revisión de código.

**Deuda aceptada a sabiendas:** si UTB Tracker creciera a escala de toda la universidad
o múltiples sedes simultáneas, el monolito modular no podría escalar módulos de forma
independiente. Se acepta ese límite porque está fuera del alcance declarado del proyecto
académico actual (ver sección 1 de arc42: sistema dirigido a los auxiliares de planta de
una única sede de la UTB).
