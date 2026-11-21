# 0024 - Sin verificación de correo; el rol lo asigna un administrador (Fase 1 del rediseño de roles)

## Estado

Aceptado (2026-11-21). **Reemplaza** de ADR-0014 el flujo de verificación de correo, y de ADR-0019
la regla de rol automático por correo verificado. Completa ADR-0018 (la tabla de permisos no
cambia en esta fase).

## Contexto

- El dominio `@utb.edu.co` ya pertenece a la universidad: verificar con un enlace que la persona
  es dueña de su correo no aporta lo que costaba (pantalla de "verificación pendiente",
  reenvíos, plantillas, páginas HTML, `VERIFICACION_OBLIGATORIA`, `USE_REAL_MAIL`).
- En la nube no hay correo real: la verificación nunca funcionó. Además, la regla "sin correo
  comprobado = rol base" dejó a las cuentas de Auditor y Administrador de prueba como
  Estudiante (hallazgo del diagnóstico del 2026-11-21).
- Quitar la verificación abre un riesgo: **cualquiera puede registrarse escribiendo el correo de
  otra persona** y, con la regla de ADR-0019, heredar su rol.

## Decisión

1. **Se quita la verificación de correo.** Sin enlaces, códigos, pantalla de verificación,
   reenvío, `require_verified`/`VerifiedUser`, `VERIFICACION_OBLIGATORIA`, `EMAIL_TOKEN_SECRET_KEY`
   ni las plantillas `verificacion` y `cambio_correo_nuevo`. `salones.solicitar` solo pide sesión
   y permiso. Se conservan `USE_REAL_MAIL` y los correos de seguridad (recuperar contraseña,
   aviso de cambio de correo o de contraseña, inicio de sesión sospechoso).
2. **Solo el dominio permitido.** El registro y el cambio de correo siguen una única regla
   (`error_correo_nuevo`, `app/core/politica.py`; espejo `politica.dart`): coincidencia EXACTA
   del dominio (`DOMINIOS_PERMITIDOS`, por defecto `utb.edu.co`), en minúsculas y sin espacios.
   Se rechazan `gmail.com`, `utb.edu.co.otro.com`, `evil-utb.edu.co`, `x.utb.edu.co` y
   `utb.edu.co@evil.com`. La app valida mientras se escribe.
3. **Mitigación de la suplantación (opción "b pura").**
   - Todo registro nace Estudiante. El cliente no elige rol.
   - Ningún correo da un rol: `rol_resuelto` (`app/services/asignaciones.py`) devuelve el rol
     guardado. Desaparecen la lista automática, el recálculo al iniciar sesión y la condición
     de correo comprobado.
   - Un rol con permisos lo pone SOLO un administrador sobre una cuenta que YA existe: pantalla
     Usuarios o carga masiva (`POST /usuarios/asignaciones/importar`).
   - La carga masiva (`correo,rol[,cargo]`) tiene vista previa y es todo o nada. Los correos sin
     cuenta se reportan como "sin cuenta" y **no quedan esperando**: quien se registre después
     con ese correo será Estudiante.
   - Cada cambio sube `sesion_version` (cierra las sesiones de esa persona), queda en la bitácora
     (quién, a quién, de qué rol a cuál, vía importación) y nunca deja el sistema sin
     administrador activo ni cambia el propio rol.
4. **Cambio de correo directo.** `POST /auth/me/cambiar-correo` cambia al instante (con la
   contraseña actual, límite de intentos y aviso al correo anterior). Como el correo ya no da
   permisos, cambiarlo nunca sube ni baja el rol.
5. **Cuentas existentes con otro dominio: se desactivan** (decisión del dueño; no se borran, un
   administrador puede reactivarlas). Migración `b3c4d5e6f7a8`: desactiva y sube
   `sesion_version`. Un administrador activo con otro dominio NO se toca (evita dejar el sistema
   sin administrador): debe pasarse a mano a un correo institucional.
6. **Compatibilidad con las APK instaladas: se rompe a propósito** (decisión del dueño). Se
   eliminan `email_verificado` de las respuestas y los endpoints `/auth/verificar-correo`,
   `/auth/reenviar-verificacion`, `/usuarios/{id}/rol/automatico` y el CRUD de
   `/usuarios/asignaciones`. Hay que instalar la APK nueva. `docs/contracts/openapi.json` se
   regeneró (la prueba de contrato compara contra él).
7. **Columnas.** `usuarios.email_verificado`, `email_verificado_en`, `rol_manual` y la tabla
   `asignaciones_rol` quedan sin uso. Se retirarán en una migración posterior (no en la misma que
   deja de usarlas, para no romper el servidor viejo durante el despliegue).

## Límites de la mitigación (honestos)

- Alguien puede registrarse primero con el correo de otra persona. La persona real verá "ya
  existe una cuenta con ese correo"; el impostor es solo un Estudiante con su nombre. Solución
  operativa: un administrador desactiva esa cuenta (queda en la bitácora). Pendiente evaluar una
  acción "liberar cuenta" que suelte el correo.
- Un impostor puede pedir salones a nombre de otro: daño bajo y reversible (se cancela y queda
  en la bitácora).
- El administrador debe comprobar la identidad fuera de la app antes de dar un rol.
- Sin correo real tampoco funciona "olvidé mi contraseña" en la nube. No se agrega clave
  temporal por ahora (decisión del dueño).
- La solución de fondo sería el inicio de sesión institucional (SSO de la UTB), que depende de
  TI de la UTB: queda anotada como mejora futura.

## Consecuencias

- Menos código y menos superficie de ataque (sin tokens de verificación ni páginas HTML).
- El registro es inmediato y funciona sin correo real.
- Un administrador carga a mano o por lista a quienes deben tener un rol.
- Fases siguientes del rediseño: una sola fuente de la matriz de permisos (archivo de datos),
  roles por función (Docente, Operador de salones, Auditor de solo lectura), varios roles con
  fecha de fin, alcance por edificio o bloque y pantalla de gestión.

## Pruebas

`tests/test_roles_sin_verificacion.py` (dominio, suplantación, carga masiva, consola),
`tests/test_correo_servicio.py`, `tests/test_matriz_permisos.py`, `tests/test_contract.py`; en la
app `test/asignaciones_test.dart`, `test/auth_controller_test.dart`,
`test/correo_institucional_test.dart`. Migración probada en PostgreSQL 18 y SQLite.
