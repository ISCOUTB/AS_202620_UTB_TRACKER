# Aspectos — UTB Tracker

Un aspecto es un corte vertical del sistema con valor propio, trazable de punta a punta:

```
aspecto → requisito → elementos C4 → ADR → código → pruebas → evidencia de calidad
```

Cada fila de la tabla debe poder recorrerse completa. En esta entrega varias
columnas quedan en `—` porque todavía no existen ADRs, código ni pruebas.

---

## A-01 · Declarar

- **Nombre:** Formularios intuitivos para auxiliares y usuarios UTB
- **Para quién:** Auxiliares de planta/laboratorio que atienden varias solicitudes seguidas, y
  estudiantes/profesores sin capacitación previa en el sistema.
- **Qué problema resuelve:** Si registrar un préstamo o reportar un daño toma demasiados pasos,
  el auxiliar vuelve al proceso manual que el sistema busca reemplazar.

## A-02 · Declarar

- **Nombre:** Acceso al sistema durante el horario del campus
- **Para quién:** Auxiliares y usuarios UTB que necesitan registrar o consultar préstamos
  durante la jornada.
- **Qué problema resuelve:** Si el sistema no responde durante el horario activo del campus,
  el registro vuelve a depender de anotaciones manuales.

## A-03 · Declarar

- **Nombre:** Respuesta rápida de la interfaz
- **Para quién:** Auxiliares atendiendo en fila y usuarios UTB en horas pico.
- **Qué problema resuelve:** Una interfaz lenta hace que el auxiliar abandone el registro a
  mitad de camino.

## A-04 · Declarar

- **Nombre:** Estabilidad con muchos usuarios simultáneos
- **Para quién:** Todo el campus, especialmente en inicio de semestre.
- **Qué problema resuelve:** Si el sistema se satura cuando muchos piden equipos a la vez, el registro queda incompleto.

**Enlace a medición:** Esta característica está validada en el informe de carga **QS‑03**: [docs/calidad/medicion-qs03.md](../calidad/medicion-qs03.md) donde se muestra que 300 usuarios concurrentes alcanzan un p95 de 2523 ms (bajo el umbral de 3000 ms).

- **Nombre:** Estabilidad con muchos usuarios simultáneos
- **Para quién:** Todo el campus, especialmente en inicio de semestre.
- **Qué problema resuelve:** Si el sistema se satura cuando muchos piden equipos a la vez, el
  registro queda incompleto.

## A-05 · Declarar

- **Nombre:** Control de acceso por rol
- **Para quién:** Estudiantes (consultan y solicitan salones), Auditores (administran todos los
  salones) y Administradores (el equipo: además usuarios, bitácora y estadísticas). Desde
  ADR-0018 los roles guardados `usuario_utb`/`auxiliar`/`administrador` se muestran con esas
  etiquetas.
- **Qué problema resuelve:** Sin control de acceso, cualquier usuario podría alterar el
  catálogo o el estado de recursos que no le corresponden. Antes de ADR-0018 el auxiliar podía
  además cambiar roles y cualquiera podía ver el correo de otros.

## A-11 · Declarar

- **Nombre:** Una experiencia completa por rol
- **Para quién:** Estudiante, Auditor y Administrador (y el equipo que prueba la app).
- **Qué problema resuelve:** La app mostraba lo mismo a auditores y administradores, el
  estudiante no veía el motivo de un rechazo y no había bandeja de solicitudes ni pantallas de
  usuarios o estadísticas. Ahora la navegación sale de los permisos reales y el administrador
  puede "ver como" otro rol sin cambiar sus permisos.

## A-12 · Declarar

- **Nombre:** Cuenta institucional con rol asignado y foto de perfil
- **Para quién:** Toda persona de la UTB que usa la app, y el Administrador que decide quién es
  Auditor o Administrador.
- **Qué problema resuelve:** Cualquiera podía registrarse con cualquier correo, el rol solo se
  cambiaba a mano y no había foto. Ahora solo se registran correos de la UTB (las cuentas
  antiguas siguen entrando y reciben un aviso), el rol sale de una lista que mantiene el
  administrador y solo aplica con el correo comprobado, y la persona pone su foto sin que se
  guarde su ubicación.

## A-06 · Declarar

- **Nombre:** Confiabilidad del estado de recursos y préstamos
- **Para quién:** Auxiliares y usuarios UTB — todos dependen de que el estado mostrado
  (disponible/prestado/dañado) sea siempre el real.
- **Qué problema resuelve:** El problema central del sistema (documento de idea, sección 2):
  hoy no hay un registro confiable de qué equipo está disponible. Si el sistema permite que dos
  préstamos coincidan sobre el mismo recurso, no mejora nada frente al proceso manual actual.

## A-07 · Declarar

- **Nombre:** Control de salones en vivo
- **Para quién:** Auxiliares de planta, que necesitan saber qué salón está libre, en clase o prestado, y si el
  profesor llegó.
- **Qué problema resuelve:** Sin una vista única, el auxiliar recorre el campus o llama para saber quién tiene
  cada salón, y no queda constancia de si el profesor llegó ni de las novedades del salón.

## A-08 · Declarar

- **Nombre:** Trazabilidad de acciones (auditoría)
- **Para quién:** El administrador, que debe poder responder "quién hizo qué y cuándo".
- **Qué problema resuelve:** Sin bitácora, una disputa sobre un salón o un cambio de rol no se puede resolver, y
  QS-04 (modificaciones no autorizadas) no se puede demostrar.

## A-09 · Declarar

- **Nombre:** Cuentas reales ligadas a un correo verificado
- **Para quién:** Estudiantes, docentes y auxiliares que se registran, y el administrador que necesita
  saber que cada cuenta es de una persona real.
- **Qué problema resuelve:** Las cuentas "no se guardaban" (la app hablaba con un servidor y la persona
  entraba en otro), el correo no se verificaba y se podían crear cuentas duplicadas por mayúsculas. Sin
  sesión renovable, la app pedía la contraseña cada hora.

## A-10 · Declarar

- **Nombre:** Elegir el salón adecuado por su tipo y equipamiento
- **Para quién:** Quien solicita un salón (necesita computadores, sonido…) y el auxiliar que lo asigna.
- **Qué problema resuelve:** Antes solo se veían código y capacidad; había que adivinar qué tenía cada
  salón aunque los equipos ya estuvieran registrados.

---

## Tabla de trazabilidad

| ID | Aspecto | Requisito | C4 | ADR | Código | Pruebas | Evidencia |
|----|---------|-----------|----|----|--------|---------|-----------|
| **A-01** | Formularios intuitivos | Usabilidad — [QS-05](arc42/arc42.md#qs-05--usabilidad) | C1, C2 | [ADR-0001](adr/0001-estilo-arquitectonico.md), [ADR-0002](adr/0002-cambio-stack-fastapi-flutter.md) | `app/schemas/schemas.py`, `app/schemas/auth.py` | `tests/test_contract.py` (2 pruebas en verde) | Contrato OpenAPI congelado en `docs/contracts/openapi.json` con validación estricta de esquemas de formulario |
| **A-02** | Acceso durante horario del campus | Disponibilidad — [QS-01](arc42/arc42.md#qs-01--disponibilidad) | C1, C2 | [ADR-0001](adr/0001-estilo-arquitectonico.md) | `app/routers/health.py::health_check` | `app/tests/test_main.py` (en verde) | Health check profundo contra PostgreSQL (`SELECT 1`) y servicio systemd en Linux con reinicio automático |
| **A-03** | Respuesta rápida | Rendimiento (tiempo) — [QS-02](arc42/arc42.md#qs-02--rendimiento-tiempo-de-respuesta) | C1, C2 | [ADR-0002](adr/0002-cambio-stack-fastapi-flutter.md) | `app/main.py::logging_middleware`, FastAPI ASGI | `tests/test_loans.py`, `tests/test_resources.py` | Middleware con medición de latencia en milisegundos (`latency_ms`) en cada petición HTTP |
| **A-04** | Estabilidad con concurrencia | Rendimiento (concurrencia) — [QS-03](arc42/arc42.md#qs-03--rendimiento-concurrencia) | C1, C2 | [ADR-0001](adr/0001-estilo-arquitectonico.md), [ADR-0005](adr/0005-monolito-vs-microservicios.md) | `app/core/database.py`, `app/core/resilience.py`, `app/main.py` | `tests/test_performance.py`, `tests/test_resilience.py` | Pool resiliente (`pool_pre_ping`, timeouts) y decorador `@with_retry` con backoff y jitter |
| **A-05** | Control de acceso por rol | Seguridad — [QS-04](arc42/arc42.md#qs-04--seguridad) | C1, C2 | [ADR-0004](adr/0004-seguridad-jwt.md), [ADR-0008](adr/0008-control-acceso-granular-recurso.md), [ADR-0025](adr/0025-matriz-de-permisos-en-un-archivo-de-datos.md), [ADR-0018](adr/0018-modelo-de-roles-y-permisos.md) | `app/core/permisos.py`, `app/core/deps.py`, `app/services/usuarios.py`, `app/routers/usuarios.py`, `app/routers/auth.py`, `app/core/security.py` | `tests/test_auth.py`, `tests/test_matriz_permisos.py`, `tests/test_roles.py` | Cada endpoint × cada rol (y sin sesión) se comprueba contra [matriz-permisos.md](seguridad/matriz-permisos.md); el registro público siempre crea Estudiante; nunca queda el sistema sin administrador; cambiar el rol cierra las sesiones de esa persona; la matriz vive en un solo archivo y la tabla de la documentación se valida contra él (`tests/test_matriz_unica.py`) |
| **A-11** | Experiencia completa por rol | Usabilidad — [QS-05](arc42/arc42.md#qs-05--usabilidad), Seguridad — [QS-04](arc42/arc42.md#qs-04--seguridad) | C2 | [ADR-0018](adr/0018-modelo-de-roles-y-permisos.md) | `frontend/lib/features/auth/domain/permisos.dart`, `frontend/lib/features/home/presentation/shell_page.dart`, `frontend/lib/features/solicitudes/`, `frontend/lib/features/admin/`, `frontend/lib/shared/sin_acceso.dart`, `app/services/prestamos_salon.py`, `app/services/estadisticas.py` | `frontend/test/roles_test.dart`, `tests/test_roles.py` | Pestañas por permisos para cada rol a 360 dp con texto grande; un 403 muestra "No tienes acceso"; el modo prueba cambia la navegación sin cambiar el rol real; la bandeja calcula los conflictos sin una consulta por solicitud |
| **A-12** | Cuenta institucional, rol asignado y foto | Seguridad — [QS-04](arc42/arc42.md#qs-04--seguridad), Usabilidad — [QS-05](arc42/arc42.md#qs-05--usabilidad) | C2 | [ADR-0019](adr/0019-correo-institucional-y-rol-por-asignacion.md), [ADR-0020](adr/0020-foto-de-perfil.md), [ADR-0024](adr/0024-sin-verificacion-de-correo-y-roles-asignados-por-administrador.md) | `app/core/politica.py`, `app/services/asignaciones.py`, `app/services/fotos.py`, `app/services/imagenes.py`, `app/routers/asignaciones.py`, `scripts/cargar_asignaciones.py`, `frontend/lib/features/admin/presentation/asignaciones_page.dart`, `frontend/lib/features/cuenta/presentation/foto_perfil_sheet.dart`, `frontend/lib/shared/foto_perfil.dart` | `tests/test_correo_institucional.py`, `tests/test_roles_sin_verificacion.py`, `tests/test_foto_perfil.py`, `frontend/test/correo_institucional_test.dart`, `frontend/test/asignaciones_test.dart`, `frontend/test/perfil_foto_test.dart` | Gmail rechazado sin configuración y casos tramposos; registro siempre Estudiante aunque se use el correo de otra persona (ADR-0024); dominios tramposos rechazados; último administrador protegido; importación todo o nada; la foto guardada no contiene el GPS de la original; perfil sin desbordes a 360 dp con texto ×1,3 |
| **A-13** | Catálogo real de salones | Confiabilidad de los datos — [QS-06](arc42/arc42.md#qs-06--confiabilidad-de-los-datos), Usabilidad — [QS-05](arc42/arc42.md#qs-05--usabilidad) | C2 | [ADR-0021](adr/0021-catalogo-de-salones-utb.md) | `app/services/catalogo.py`, `app/routers/catalogo.py`, `scripts/datos/catalogo_utb.json`, `scripts/cargar_catalogo_utb.py`, `frontend/lib/features/salones_admin/domain/catalogo.dart`, `frontend/lib/features/salones_admin/presentation/catalogo_page.dart` | `tests/test_catalogo_salones.py`, `frontend/test/catalogo_test.dart` | Códigos mal formados o con edificio/piso distintos → 422; el Auditor recibe 403 al crear, renombrar o desactivar; crear varios exige vista previa y no duplica; la carga es idempotente, `--simular` no escribe y nunca toca lo existente; orden natural y filtros por edificio y piso |
| **A-14** | Disponibilidad real del salón y sus equipos | Confiabilidad de los datos — [QS-06](arc42/arc42.md#qs-06--confiabilidad-de-los-datos), Rendimiento — [QS-02](arc42/arc42.md#qs-02--rendimiento-tiempo-de-respuesta), Usabilidad — [QS-05](arc42/arc42.md#qs-05--usabilidad) | C2 | [ADR-0022](adr/0022-habilitacion-ocupacion-y-equipos-del-salon.md) | `app/services/estado_salon.py`, `app/services/equipos.py`, `app/services/exportar.py`, `app/routers/estado_salon.py`, `app/services/salones_admin.py` (`_ocupaciones`), `frontend/lib/features/salones_admin/presentation/disponibilidad_secciones.dart` | `tests/test_habilitacion_equipos.py`, `frontend/test/habilitacion_test.dart` | Ocupado se calcula y no se guarda; motivo obligatorio (422); salón deshabilitado → 409 al pedir o aprobar; solicitudes afectadas señaladas y avisadas una sola vez sin cancelarse; cliente viejo con `estado` → habilitación; "prestado" → 422; dañado baja operativos y no total; plantillas sin duplicar; mismas consultas con 2 y con 10 salones |
| **A-15** | Arquitectura que no se erosiona | Mantenibilidad — [§8.1](arc42/arc42.md#81-patrón-de-capas-y-control-de-erosión-arquitectónica) | C2 | [ADR-0023](adr/0023-retiro-del-prestamo-de-equipos-y-control-de-erosion.md), [ADR-0001](adr/0001-estilo-arquitectonico.md) | `tests/test_erosion_capas.py`, `app/services/estadisticas.py` (`resumen_operativo`), `app/services/salud.py`, `app/services/maintenance.py` (`registrar_mantenimiento`), `alembic/versions/e1f2a3b4c5d6_retirar_estado_prestado_de_equipos.py` | `tests/test_erosion_capas.py`, `tests/test_habilitacion_equipos.py` (prestado → 422, legado obsoleto) | Las 3 rupturas encontradas se corrigieron y la regla queda en el CI; la migración se probó en PostgreSQL (huérfano → disponible y auditado; con préstamo activo → intacto) |
| **A-08** | Trazabilidad de acciones (auditoría) | Seguridad — [QS-04](arc42/arc42.md#qs-04--seguridad) | C1, C2 | [ADR-0010](adr/0010-auditoria.md) | `app/models/auditoria_models.py`, `app/services/auditoria.py`, `app/routers/auditoria.py`, `alembic/versions/a1b2c3d4e5f6_add_auditoria.py` | `tests/test_auditoria.py` (12 pruebas: qué se registra, permisos, filtros, CSV, inmutabilidad) | Cada acción auditada guarda actor, hora, antes y después en la misma transacción; la bitácora no se puede editar ni borrar |
| **A-07** | Control de salones en vivo | Usabilidad — [QS-05](arc42/arc42.md#qs-05--usabilidad) | C1, C2 | [ADR-0009](adr/0009-administracion-de-salones.md) | `app/services/salones_admin.py`, `app/routers/salones_admin.py`, `frontend/lib/features/salones_admin/` | `tests/test_salones_admin.py`, `frontend/test/salones_admin_test.dart` | `GET /salones/ocupacion` calcula en el servidor quién tiene cada salón; el panel del auxiliar se pinta con una sola petición |
| **A-09** | Cuentas con correo verificado | Seguridad — [QS-04](arc42/arc42.md#qs-04--seguridad) | C1, C2 | [ADR-0014](adr/0014-autenticacion-correo-verificado-y-tokens-por-id.md) (la verificación se retiró en ADR-0024), [ADR-0015](adr/0015-servicio-de-correo.md), [ADR-0016](adr/0016-perfil-y-preferencias-en-el-servidor.md) | `app/services/auth.py`, `app/services/perfil.py`, `app/services/correo.py`, `app/core/security.py`, `app/core/deps.py`, `frontend/lib/core/network/api_client.dart`, `frontend/lib/features/auth/`, `frontend/lib/features/cuenta/` | `tests/test_identidad.py`, `tests/test_correo_servicio.py`, `tests/test_perfil.py`, `tests/test_persistencia_cuentas.py`, `frontend/test/sesion_test.dart`, `frontend/test/auth_controller_test.dart`, `frontend/test/perfil_test.dart` | Una cuenta registrada sigue existiendo tras reiniciar la API (prueba con procesos reales); los enlaces del correo sirven una sola vez; un token de verificación no sirve para recuperar contraseña ni para entrar |
| **A-10** | Tipo y equipamiento del salón | Usabilidad — [QS-05](arc42/arc42.md#qs-05--usabilidad) | C2 | [ADR-0017](adr/0017-tipo-de-salon-y-equipamiento-calculado.md) | `app/services/equipamiento.py`, `app/services/salones.py`, `frontend/lib/shared/equipamiento_chips.dart` | `tests/test_salones_tipo_equipamiento.py`, `frontend/test/equipamiento_test.dart`, `frontend/test/escala_test.dart` | El equipamiento se calcula en una sola consulta para todos los salones (prueba que cuenta las consultas con 2 y con 12 salones) |
| **A-06** | Confiabilidad del estado de recursos y préstamos | Confiabilidad de los datos — [QS-06](arc42/arc42.md#qs-06--confiabilidad-de-los-datos) | C1, C2, C3 | [ADR-0001](adr/0001-estilo-arquitectonico.md), [ADR-0003](adr/0003-integracion-sincrona.md) | `app/routers/loans.py`, `app/services/loans.py`, `app/models/recurso_models.py` | `tests/test_loans.py`, `tests/test_resilience.py` (idempotencia y locking) | Regla de negocio QS-06: bloqueo pesimista `.with_for_update()` e idempotencia vía `X-Idempotency-Key` |



---

## Especificar (escenarios medibles)

Los 6 escenarios de calidad (QS-01 a QS-06) están definidos en `docs/arc42.md`, sección
"Requisitos de calidad". A-06 es el primer aspecto de esta tabla que recorre la cadena
completa — desde el requisito hasta la evidencia de prueba real — porque es el que tiene el
corte vertical de esta entrega (S4) detrás. Los demás aspectos avanzan en las siguientes
entregas a medida que se implementen sus módulos correspondientes.
