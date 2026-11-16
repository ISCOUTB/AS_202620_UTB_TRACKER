# Matriz de permisos — UTB Tracker (ADR-0018)

Fuente única en el código: [`app/core/permisos.py`](../../app/core/permisos.py). Los routers
piden un permiso (`require_permiso`, alias en `app/core/deps.py`) y la app recibe la lista en
`GET /auth/me` (`permisos`). **Esta tabla la verifica `tests/test_matriz_permisos.py`**:
si se agrega un endpoint sin fila aquí, o la fila no coincide con el código, la prueba falla.

## Roles

| Valor guardado (`rol`) | Etiqueta (`rol_etiqueta`) | Quién es |
|---|---|---|
| `usuario_utb` | Estudiante | Solicita salones (los equipos son fijos en cada salón, no se prestan) |
| `auxiliar` | Auditor | Administra todos los salones: solicitudes, presencia, reportes, equipos, horarios |
| `administrador` | Administrador | El equipo: todo lo del auditor + usuarios, bitácora de auditoría, estadísticas, modo prueba |

"Auditor" es un **rol** (administra salones). La "auditoría" es la **bitácora** de cambios
(ADR-0010), que solo ve el administrador.

## Permisos por rol

| Permiso | Estudiante | Auditor | Administrador |
|---|:-:|:-:|:-:|
| `salones.ver` | ✅ | ✅ | ✅ |
| `salones.solicitar` (además exige correo verificado) | ✅ | ✅ | ✅ |
| `solicitudes.propias` | ✅ | ✅ | ✅ |
| `reportes.crear` | ✅ | ✅ | ✅ |
| `equipos.ver` | ✅ | ✅ | ✅ |
| `horarios.ver` | ✅ | ✅ | ✅ |
| `solicitudes.gestionar` | — | ✅ | ✅ |
| `salones.administrar` | — | ✅ | ✅ |
| `reportes.gestionar` | — | ✅ | ✅ |
| `equipos.gestionar` | — | ✅ | ✅ |
| `horarios.gestionar` | — | ✅ | ✅ |
| `usuarios.ver` | — | ✅ | ✅ |
| `usuarios.gestionar` | — | — | ✅ |
| `auditoria.ver` | — | — | ✅ |
| `estadisticas.ver` | — | — | ✅ |
| `modo_prueba` | — | — | ✅ |

Decisiones: el estudiante **sí puede reportar** un problema de un salón o equipo (quien está en
el salón lo ve primero); el auditor y el administrador también pueden solicitar salones (no
estorba y conserva el comportamiento anterior). `salones.solicitar` exige además correo
verificado (ADR-0014).

## Endpoints

Columnas: **Antes** = lo que exigía el código antes de ADR-0018 (inventario automático de
las dependencias). **Ahora** = `público`, `sesión` (cualquier usuario con sesión), `propio o
<permiso>` (sus propios datos, o los de otros con ese permiso) o el permiso exigido. ⚠ marca
los huecos corregidos.

| Método | Ruta | Antes | Ahora | Nota |
|---|---|---|---|---|
| GET | `/salud` | público | público | |
| POST | `/auth/login` | público | público | |
| POST | `/auth/register` | público | público | Siempre crea Estudiante, aunque el cuerpo traiga otro rol; solo correos institucionales (ADR-0019) |
| GET | `/auth/verificar-correo` | público | público | Enlace del correo |
| POST | `/auth/reenviar-verificacion` | sesión | sesión | |
| GET | `/auth/restablecer` | público | público | Página del enlace de recuperación |
| GET | `/auth/me` | sesión | sesión | Devuelve `rol_etiqueta` y `permisos` |
| PATCH | `/auth/me` | sesión | sesión | No permite cambiar el rol |
| POST | `/auth/me/cambiar-password` | sesión | sesión | |
| POST | `/auth/me/cerrar-sesiones` | sesión | sesión | |
| POST | `/auth/me/desactivar` | sesión | sesión | El último administrador no puede desactivarse (409) |
| POST | `/auth/me/cambiar-correo` | sesión | sesión | ADR-0019: solo correos institucionales |
| PUT | `/auth/me/foto` | — | sesión | ADR-0020: solo la propia; JPEG/PNG por firma, tamaño y frecuencia limitados |
| DELETE | `/auth/me/foto` | — | sesión | ADR-0020: borra el contenido |
| GET | `/auth/me/foto` | — | sesión | ADR-0020 |
| DELETE | `/auth/delete/{user_id}` | auxiliar o admin | usuarios.gestionar | ⚠ el auxiliar podía desactivar cuentas |
| GET | `/auth/user/{user_id}` | sesión | propio o usuarios.ver | ⚠ cualquiera veía el correo de cualquiera |
| GET | `/auth/users` | auxiliar o admin | usuarios.gestionar | ⚠ el auxiliar listaba todas las cuentas |
| PUT | `/auth/user/{user_id}/role` | auxiliar o admin | usuarios.gestionar | ⚠ el auxiliar podía hacerse administrador a otros |
| PATCH | `/auth/user/{user_id}/role` | auxiliar o admin | usuarios.gestionar | ⚠ ídem |
| POST | `/auth/forgot-password` | público | público | |
| POST | `/auth/reset-password` | público | público | |
| POST | `/auth/refresh` | público | público | Usa el refresh token |
| PATCH | `/auth/fcm-token` | sesión | sesión | |
| POST | `/recursos` | auxiliar o admin | equipos.gestionar | |
| GET | `/recursos` | sesión | equipos.ver | |
| GET | `/recursos/{recurso_id}` | sesión | equipos.ver | |
| PUT | `/recursos/{recurso_id}` | auxiliar o admin | equipos.gestionar | |
| DELETE | `/recursos/{recurso_id}` | auxiliar o admin | equipos.gestionar | |
| POST | `/recursos/{recurso_id}/reportar` | sesión | reportes.crear | |
| GET | `/recursos/{recurso_id}/reportes` | sesión | equipos.ver | |
| POST | `/prestamos` | sesión | equipos.gestionar | ⚠ legado: cualquiera prestaba equipos (ADR-0010: no se prestan) |
| GET | `/prestamos` | sesión | equipos.gestionar | ⚠ legado |
| PATCH | `/prestamos/{prestamo_id}/devolver` | sesión | equipos.gestionar | ⚠ legado: cualquiera devolvía préstamos ajenos |
| POST | `/prestamos/marcar-vencidos` | auxiliar o admin | equipos.gestionar | Legado |
| POST | `/prestamos/jobs/marcar-vencidos` | auxiliar o admin | equipos.gestionar | Legado |
| GET | `/salones/ocupacion` | auxiliar o admin | salones.administrar | |
| GET | `/salones/{salon_id}/ocupacion` | auxiliar o admin | salones.administrar | |
| PUT | `/salones/{salon_id}/presencia` | auxiliar o admin | salones.administrar | |
| POST | `/salones/{salon_id}/reportes` | sesión | reportes.crear | |
| GET | `/salones/reportes` | auxiliar o admin | reportes.gestionar | |
| GET | `/salones/{salon_id}/reportes` | sesión | reportes.gestionar | ⚠ cualquiera leía los reportes (con nombres) |
| PATCH | `/salones/{salon_id}/reportes/{reporte_id}` | auxiliar o admin | reportes.gestionar | |
| POST | `/salones` | auxiliar o admin | salones.administrar | |
| GET | `/salones` | sesión | salones.ver | |
| GET | `/salones/{salon_id}` | sesión | salones.ver | |
| PUT | `/salones/{salon_id}` | auxiliar o admin | salones.administrar | |
| DELETE | `/salones/{salon_id}` | auxiliar o admin | salones.administrar | |
| GET | `/salones/{salon_id}/disponibilidad` | sesión | salones.ver | |
| POST | `/horarios` | auxiliar o admin | horarios.gestionar | |
| POST | `/horarios/bulk` | auxiliar o admin | horarios.gestionar | |
| GET | `/horarios` | sesión | horarios.ver | |
| GET | `/horarios/{horario_id}` | sesión | horarios.ver | |
| PUT | `/horarios/{horario_id}` | auxiliar o admin | horarios.gestionar | |
| DELETE | `/horarios/{horario_id}` | auxiliar o admin | horarios.gestionar | |
| POST | `/prestamos-salon` | sesión + verificado | salones.solicitar | Exige correo verificado |
| GET | `/prestamos-salon/mias` | — | solicitudes.propias | Nuevo: mis solicitudes |
| GET | `/prestamos-salon/gestion` | — | solicitudes.gestionar | Nuevo: bandeja con conflicto visible |
| GET | `/prestamos-salon` | sesión | solicitudes.propias | El estudiante solo recibe las suyas |
| GET | `/prestamos-salon/{prestamo_id}` | sesión | solicitudes.propias | El estudiante solo la suya (403 si es ajena) |
| PATCH | `/prestamos-salon/{prestamo_id}` | auxiliar o admin | solicitudes.gestionar | Acepta `respuesta` opcional |
| POST | `/prestamos-salon/{prestamo_id}/aprobar` | — | solicitudes.gestionar | Nuevo |
| POST | `/prestamos-salon/{prestamo_id}/rechazar` | — | solicitudes.gestionar | Nuevo: motivo obligatorio |
| DELETE | `/prestamos-salon/{prestamo_id}` | sesión | solicitudes.propias | Solo la propia y pendiente |
| POST | `/prestamos-salon/expirar` | auxiliar o admin | solicitudes.gestionar | |
| POST | `/mantenimientos` | auxiliar o admin | equipos.gestionar | |
| GET | `/mantenimientos` | sesión | equipos.gestionar | ⚠ cualquiera veía el historial de mantenimiento |
| PATCH | `/mantenimientos/{mantenimiento_id}` | auxiliar o admin | equipos.gestionar | |
| GET | `/stats/resumen` | sesión | salones.administrar | ⚠ indicadores operativos visibles para cualquiera (la app no los usaba con estudiantes) |
| GET | `/stats/admin` | — | estadisticas.ver | Nuevo |
| GET | `/auditoria` | admin | auditoria.ver | Bitácora (ADR-0010) |
| GET | `/auditoria/exportar` | admin | auditoria.ver | CSV |
| GET | `/usuarios` | — | usuarios.gestionar | Nuevo: búsqueda, rol, última actividad |
| PATCH | `/usuarios/{usuario_id}/rol` | — | usuarios.gestionar | Nuevo: 409 sobre sí mismo o último administrador |
| PATCH | `/usuarios/{usuario_id}/estado` | — | usuarios.gestionar | Nuevo: ídem |
| POST | `/usuarios/{usuario_id}/rol/automatico` | — | usuarios.gestionar | ADR-0019: quita el rol manual y aplica la lista |
| GET | `/usuarios/{usuario_id}/foto` | — | propio o usuarios.ver | ADR-0020: nunca pública |
| GET | `/usuarios/asignaciones` | — | usuarios.gestionar | ADR-0019: lista de asignación de roles por correo |
| POST | `/usuarios/asignaciones` | — | usuarios.gestionar | ADR-0019: 409 si ya existe o dejaría sin administrador |
| POST | `/usuarios/asignaciones/importar` | — | usuarios.gestionar | ADR-0019: todo o nada, errores por línea |
| PATCH | `/usuarios/asignaciones/{asignacion_id}` | — | usuarios.gestionar | ADR-0019 |
| DELETE | `/usuarios/asignaciones/{asignacion_id}` | — | usuarios.gestionar | ADR-0019: protege al último administrador |

## Compatibilidad con las APK instaladas

El valor de `rol` no cambió y todas las respuestas solo **agregan** campos. Una APK anterior
sigue funcionando, con dos diferencias buscadas: un **auditor** (`auxiliar`) que abra el panel
de usuarios de la APK vieja recibe "No tienes permiso" (gestionar usuarios es solo del
administrador), y la APK vieja muestra a un auditor como "Auxiliar de planta".
