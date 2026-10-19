# ADR-0005: Preservación del Monolito Modular — Decisión de No Extraer Microservicios

## Estado

Aceptado

## Contexto

Durante la etapa de evaluación arquitectónica de la Semana 11, se analizó la posibilidad
de extraer módulos de dominio (por ejemplo, el catálogo de `Recursos` o el servicio de
`Usuarios/Auth`) como microservicios independientes desplegados por separado.

El sistema atiende un máximo de **300 usuarios simultáneos** en hora pico del campus
(escenario QS-03), opera sobre una **única base de datos PostgreSQL** y es mantenido
por un equipo de **4 estudiantes** con tiempo limitado de desarrollo.

Esta decisión corresponde al aspecto **11.6 (Evaluación de Extracción a Microservicios)**
del informe de auditoría de Semana 11.

## Decisión

Se decide **NO extraer ningún módulo a microservicio** y preservar el estilo de
**Monolito Modular** en un único desplegable FastAPI respaldado por una única base de
datos PostgreSQL.

## Alternativas evaluadas

**1. Extraer módulo de Recursos a microservicio independiente.**
- *Descartada:* la creación de un préstamo depende de la validación atómica del estado
  del recurso. Separar ambos servicios exigiría comunicación síncrona HTTP entre
  microservicios (aumentando la latencia y duplicando los puntos de falla) o consistencia
  eventual — lo cual viola directamente QS-06 (confiabilidad de los datos) si dos
  solicitudes paralelas se cruzan durante una partición de red.

**2. Extraer Autenticación a un microservicio dedicado.**
- *Descartada:* al usar tokens JWT autofirmados y sin estado (ADR-0004), la verificación
  de identidad y roles ocurre de forma local en cada instancia del backend sin necesidad
  de consultar remotamente ningún servicio externo en cada request. Separarlo añadiría
  latencia de red sin ningún beneficio.

**3. Mantener Monolito Modular (seleccionada).**
- Mantiene fronteras lógicas claras entre módulos de dominio bajo `app/routers/`,
  permitiendo trabajo en paralelo dentro del equipo sin la sobrecarga operativa del
  despliegue distribuido.

## Consecuencias

**Positivas:**
- Transacciones ACID atómicas simples para garantizar QS-06 (confiabilidad de datos):
  la validación de disponibilidad del recurso y la creación del préstamo ocurren en un
  único `db.commit()` dentro de la misma sesión SQLAlchemy.
- Cero latencia de red entre módulos: toda la comunicación inter-módulo es una llamada
  de función Python en el mismo proceso.
- Despliegue y monitoreo simples en un único VPS con `systemd` y un único proceso
  Uvicorn.
- Menor costo operativo: no hay service discovery, proxies, ni distributed tracing.

**Negativas / límites aceptados:**
- Todos los módulos comparten el mismo ciclo de despliegue y escalado horizontal
  conjunto. Si en el futuro el volumen superara los miles de requests por segundo de
  forma sostenida, podría revisarse esta decisión — ese escenario está fuera del alcance
  declarado del sistema universitario actual.
