# 0016 - Perfil personalizable y preferencias guardadas en el servidor

## Estado

Aceptado (2026-11-14).

## Contexto

El perfil solo mostraba nombre, correo y rol, sin forma de editarlos. Tampoco había manera de
cambiar la contraseña con la sesión abierta, cerrar sesiones robadas ni elegir qué avisos
recibir. Además, el auxiliar usa la app en el celular y en el PC: si las preferencias
vivieran en el dispositivo, tendría que configurarlas dos veces y el worker (que decide si
envía un correo) no podría leerlas.

## Decisión

1. **Perfil:** `GET /auth/me` devuelve el perfil completo y `PATCH /auth/me` edita solo lo
   enviado: nombre para mostrar, teléfono, dependencia/cargo y color de avatar (`#RRGGBB`). Un
   texto vacío borra el campo. El esquema rechaza campos desconocidos, así que por aquí no se
   puede cambiar el rol.
2. **Preferencias en el servidor** (`usuarios.preferencias`, JSON con valores por defecto):
   - avisos por **canal** (correo, push) y **tipo** (`cuenta`, `salones`);
   - **tamaño de texto** (normal, grande, extra grande), que la app aplica al iniciar sesión
     (Fase 3);
   - **pantalla de inicio** (Inicio, Salones o Control), útil al auxiliar.
   Una cuenta sin preferencias guardadas se comporta como "todo encendido, texto normal".
3. **El worker respeta las preferencias**, salvo los correos de **seguridad** (verificación,
   recuperación, cambio de correo o de contraseña, alerta de inicio de sesión), que salen
   siempre. Un aviso omitido queda en el outbox como `enviado` con
   `ultimo_error = "omitido por preferencia del usuario"`, para poder rastrearlo.
4. **Seguridad de la cuenta:**
   - `POST /auth/me/cambiar-password` pide la contraseña actual, aplica la política, avisa por
     correo y sube `sesion_version`: los tokens de los demás dispositivos dejan de valer. La
     respuesta trae tokens nuevos para el dispositivo actual.
   - `POST /auth/me/cerrar-sesiones` hace lo mismo sin cambiar la contraseña.
   - `POST /auth/me/desactivar` (con la contraseña) desactiva la cuenta propia y cierra todas
     sus sesiones; no se borra para conservar la auditoría.
   - Las acciones que piden la contraseña actual tienen un límite de 5 intentos cada 5 minutos.
5. Todo queda en la auditoría (`usuario.perfil` con los **nombres** de los campos,
   `usuario.cambiar_password`, `usuario.cerrar_sesiones`, `usuario.desactivar_propia`,
   `usuario.cambio_correo_solicitado`, `usuario.cambio_correo`).

## Alternativas consideradas

- **Preferencias en el dispositivo** (`shared_preferences`): no viajan entre celular y web, el
  worker no las conoce y exigía un paquete nuevo.
- **Lista negra de tokens** en lugar de versión de sesión: permite revocar un solo token, pero
  obliga a consultar una tabla en cada petición. Con un entero en el usuario basta para "cerrar
  las demás sesiones".
- **Tabla aparte de preferencias** (una fila por clave): más normalizada, pero cada lectura del
  perfil haría un JOIN y el esquema cambiaría con cada preferencia nueva. JSON con valores por
  defecto validados por Pydantic es suficiente.

## Consecuencias

- **Positivas:** la persona controla sus datos y sus avisos; un robo de sesión se corta desde
  Perfil > Seguridad.
- **Negativas:** el JSON no se valida en la base (lo valida el esquema de Pydantic); un cambio de
  contraseña cierra también las sesiones web abiertas por la misma persona.

## Trazabilidad

| Decisión | Código | Pruebas |
|---|---|---|
| Perfil y preferencias | `app/schemas/perfil.py`, `app/service/perfil.py`, `app/handler/auth.py`, migración `d4e5f6a7b8c9` | `tests/test_perfil.py` |
| Worker respeta preferencias | `app/messaging/worker.py::_preferencia_permite` | `test_worker_respeta_preferencias_salvo_seguridad`, `test_worker_respeta_preferencia_de_avisos_de_salones` |
| Versión de sesión | `app/middleware/deps.py::sesion_vigente`, `app/middleware/security.py` | `test_cambiar_password_cierra_las_demas_sesiones`, `test_cerrar_sesiones_en_todos_los_dispositivos` |
| Pantalla de perfil | `frontend/lib/features/cuenta/presentation/cuenta_page.dart`, `frontend/lib/features/auth/domain/preferencias.dart` | `frontend/test/perfil_test.dart` |
| Privacidad | `docs/seguridad/privacidad.md` §6 | — |
