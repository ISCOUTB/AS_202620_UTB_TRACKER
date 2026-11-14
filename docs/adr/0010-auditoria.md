# 0010 - Auditoría: bitácora de solo-agregar escrita en la misma transacción

## Estado

Aceptado

## Contexto

El sistema decide cosas que afectan a personas: quién tiene un salón, si un profesor llegó o no,
qué solicitudes se aprueban, quién recibe rol de auxiliar o administrador. Hoy esas acciones
cambian el dato, pero no dejan rastro de **quién** las hizo ni **cuándo**. Sin eso, una disputa
("yo sí llegué", "nadie aprobó esto") no se puede resolver, y el objetivo de seguridad
(QS-04, 0 % de modificaciones no autorizadas) no se puede demostrar con evidencia.

## Decisión

Se agrega una tabla `auditoria` y un servicio `app/services/auditoria.py`:

- **Qué se registra:** quién (`actor_id` y `actor_nombre`), cuándo (UTC), qué acción
  (`salon.presencia`, `salon.solicitud.estado`, `usuario.rol`…), sobre qué entidad y un `detalle`
  en JSON con el antes y el después. También `auth.login` y `auth.login_fallido` (con el nombre
  probado, **nunca** la contraseña) y el `request_id` que une el registro con el log HTTP.
- **Misma transacción:** `registrar()` agrega la fila a la sesión del cambio y no hace commit;
  el servicio confirma todo junto. Si la acción falla o se revierte, no queda registro de algo que no
  pasó (hay una prueba que lo verifica).
- **Solo-agregar:** ningún endpoint crea, edita ni borra registros; el ORM lanza `PermissionError`
  ante un `UPDATE` o `DELETE`, y en PostgreSQL la migración añade un trigger que los rechaza también
  a nivel de base de datos.
- **Consulta:** `GET /auditoria` (filtros por acción —exacta o por prefijo—, entidad, actor y rango
  de fechas, con paginación) y `GET /auditoria/exportar` (CSV). Solo rol **administrador**: el
  auxiliar opera, el administrador supervisa.
- **Cobertura inicial:** salones (crear, actualizar, eliminar, presencia del profesor, reportes,
  solicitudes de préstamo de salón), horarios, recursos y mantenimientos, y usuarios (registro, login,
  cambio de rol, desactivación).

Los servicios reciben el actor como parámetro opcional `actor_id` (el router lo pasa desde el
usuario autenticado); sin actor, el registro queda con actor vacío.

## Alternativas consideradas

**Auditar en un middleware HTTP** (registrar cada petición). Se descartó: registra peticiones, no
decisiones; no sabe el antes y el después, y dejaría registros de peticiones que luego fallaron.

**Triggers de base de datos para todo.** Se descartó como mecanismo principal porque no conocen al
usuario de la aplicación (solo ven la conexión). Se usa solo para la protección de inmutabilidad.

**Variable de contexto con el actor** (para no pasar `actor_id`). Se descartó: FastAPI ejecuta
dependencias y endpoints síncronos en hilos distintos, y el valor no llega con seguridad al servicio.

## Consecuencias

**Se gana:** evidencia de quién hizo qué, resolución de disputas y una respuesta concreta a QS-04.

**Se asume:** cada acción auditada escribe una fila más (un `INSERT` en la misma transacción) y la
tabla crece sin límite. Con el volumen de un campus es aceptable; si crece, habrá que particionar por
fecha o archivar. Quien añada una acción nueva debe llamar a `registrar` (no hay forma automática de
detectar que falta).

**Deuda aceptada a sabiendas:** el administrador ve la bitácora por API, pero todavía no hay pantalla en
la app. Los préstamos de recursos (`/prestamos`) no se auditan: el equipo decidió que los equipos no se
prestan. La retención y el borrado por plazo legal (privacidad, `docs/seguridad/privacidad.md`) no están
definidos.
