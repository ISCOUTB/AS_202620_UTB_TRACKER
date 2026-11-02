# ADR-0008: Control de Acceso Granular por Recurso (Mitigación BOLA/IDOR)

## Estado

Propuesto (Mitigación arquitectónica derivada del modelado de amenazas S13 para resolver las vulnerabilidades T-03, T-04 y T-06).

## Fecha

31 de octubre de 2026

## Contexto

El sistema UTB Tracker implementó en el [ADR-0004](0004-seguridad-jwt.md) un modelo de autenticación y autorización basado en roles (RBAC) mediante dependencias de FastAPI (`CurrentUser` y `AdminUser` en `app/core/deps.py:78-79`). Dicho esquema valida exitosamente si una petición proviene de un usuario autenticado o si posee el rol de `"administrador"` o `"auxiliar"`.

Sin embargo, el modelado de amenazas formal (S13 — `docs/seguridad/modelo-amenazas.md`) evidenció que el control basado exclusivamente en roles es insuficiente para proteger recursos individuales, dejando abiertas brechas críticas de autorización a nivel de objeto (Broken Object Level Authorization — BOLA / Insecure Direct Object References — IDOR):
1. **Enumeración de perfiles (`GET /auth/user/{user_id}` en `app/routers/auth.py:53-59`):** Cualquier usuario autenticado puede consultar el perfil privado de cualquier otro usuario, facilitado por el uso de identificadores enteros secuenciales ([ADR-0007](0007-identificadores-enteros-autoincrementales.md)).
2. **Creación de préstamos a nombre de terceros (`POST /prestamos` en `app/services/loans.py:46-48`):** Un estudiante autenticado puede emitir peticiones asignando un `usuario_id` ajeno en el cuerpo JSON, comprometiendo a otro titular sin su consentimiento.
3. **Devolución arbitraria de préstamos (`PATCH /prestamos/{id}/devolver` en `app/routers/loans.py:72-81`):** No se valida la titularidad del préstamo devuelto, permitiendo a cualquier estudiante marcar como devueltos equipos físicos en posesión de otros usuarios.

## Decisión

Se decide adoptar un esquema de **Control de Acceso Basado en Propiedad de Recursos (Resource-Level Ownership Authorization / ABAC ligero)** aplicado de forma consistente en la capa de servicios y enrutamiento del backend FastAPI:

1. **Invariante de Titularidad o Rol Privilegiado:**  
   Toda operación sobre una entidad que contenga un campo `usuario_id` debe cumplir la regla de autorización:
   $$\text{Permitido} \iff (\text{current\_user.rol} \in \{\text{"administrador"}, \text{"auxiliar"}\}) \lor (\text{recurso.usuario\_id} = \text{current\_user.id})$$
2. **Inyección del Usuario Autenticado en Capa de Servicio:**  
   Las funciones de servicio que ejecutan mutaciones o consultas sobre recursos privados (`crear_prestamo`, `devolver_prestamo`, `get_user_by_id`, `listar_prestamos`) deben recibir obligatoriamente el objeto `current_user: Usuario` (o su `id` y `rol`), desacoplando la regla de autorización dentro de la lógica de dominio.
3. **Restricción Estricta en Registro Público:**  
   En `app/services/auth.py:create_user`, se elimina la posibilidad de recibir roles en el cuerpo JSON del registro, asignando de manera forzada e inmutable `rol = "usuario_utb"`. Los roles de auxiliar o administrador solo podrán ser asignados mediante un endpoint exclusivo protegido por `AdminUser`.

## Alternativas Evaluadas

1. **Migrar todos los identificadores a UUID v4:**
   - *Ventajas:* Hace que los IDs sean incalculables y elimina la enumeración por fuerza bruta.
   - *Descarte:* Como se demostró en el [ADR-0007](0007-identificadores-enteros-autoincrementales.md), el costo de reversión es inasumible (10 tablas, 9 FKs, 16 endpoints y 14 vistas en Flutter). Además, el oscurecimiento de identificadores no reemplaza la autorización: si un atacante obtiene un UUID por un enlace o fuga, seguiría pudiendo devolver o consultar el recurso ajeno sin validación de permisos.
2. **Filtro exclusivo en la capa de enrutamiento (FastAPI Depends):**
   - *Ventajas:* Centraliza la validación antes de entrar al servicio.
   - *Descarte:* Requiere consultas duplicadas a la base de datos (una en la dependencia para chequear el dueño y otra en el servicio para ejecutar la lógica), degradando el rendimiento en escenarios de alta concurrencia (QS-03).
3. **Control de Acceso Basado en Políticas Externas (OPA / Open Policy Agent):**
   - *Ventajas:* Desacoplamiento absoluto de las reglas de seguridad fuera del monolito.
   - *Descarte:* Introduce un nuevo contenedor/servicio en red y latencia HTTP adicional para cada petición, violando la restricción de arquitectura monolítica modular simple ([ADR-0001](0001-estilo-arquitectonico.md), [ADR-0005](0005-monolito-vs-microservicios.md)).

## Consecuencias

**Positivas:**
- Mitiga de raíz las amenazas T-01, T-03, T-04 y T-06 identificadas en el modelado de amenazas S13.
- Preserva la estructura monolítica y el uso de identificadores enteros autoincrementales sin incurrir en costos de migración de esquema en la base de datos.
- Previene que usuarios maliciosos interactúen con préstamos o perfiles institucionales ajenos.

**Negativas:**
- Requiere actualizar las firmas de las funciones en `app/services/loans.py`, `app/services/auth.py` y `app/routers/` para propagar `current_user`.
- Exige actualizar las pruebas existentes en `tests/test_loans.py` y `tests/test_auth.py` para suministrar usuarios con tokens acordes a cada escenario de prueba.
