# 0019 - Solo correos institucionales y rol por asignación verificada

## Estado

Aceptado (2026-11-16). Completa ADR-0014 (correo verificado) y ADR-0018 (roles y permisos).

## Contexto

- Cualquiera podía registrarse con cualquier correo, también con uno de Gmail. La app es de la
  UTB y solo deberían entrar personas de la UTB.
- El rol se cambiaba solo a mano desde el panel. Además, el registro aceptaba un campo `rol`
  en el cuerpo, aunque lo ignoraba.
- El correo `@utb.edu.co` **no distingue** a un estudiante de un funcionario. El patrón
  "inicial + apellido" (`mmillan@utb.edu.co`) no es confiable: deducir el rol del formato le
  daría un rol alto a quien no corresponde.
- En producción todavía no hay correo real (`USE_REAL_MAIL` apagado). Sin él, las cuentas
  nuevas nacen "verificadas" sin haber demostrado que el correo es suyo (ADR-0014, punto 11).
- Restricciones: el despliegue es automático, el `.env` de producción no se puede editar, hay
  APK instaladas y ya existen cuentas (entre ellas el administrador y las demo) que no se
  pueden bloquear.

## Decisión

### 1. Solo correos institucionales en correos NUEVOS

- **Configuración.** `DOMINIOS_PERMITIDOS` (en `app/core/config.py`) es una lista separada por
  comas. Su valor por defecto es `utb.edu.co`, así que producción no necesita la variable.
- **Coincidencia exacta.** Se compara lo que va después de la **última** `@`. Por eso:
  - Un subdominio (`estudiantes.utb.edu.co`) **no** entra si no está en la lista. Si la UTB lo
    usa, el administrador lo agrega a la lista por configuración.
  - `usuario@utb.edu.co.malo.com` no entra.
- **Una sola regla.** Vive en `app/core/politica.py` (`error_correo_nuevo`), con su espejo
  en la app (`frontend/lib/core/utils/politica.dart`, `errorCorreoNuevo`): mismas reglas y
  mismo mensaje.
- **Cómo se revisa un correo.**
  - Primero se normaliza (minúsculas, sin espacios).
  - Se exige una sola `@`.
  - Lo que va antes de la `@`: de 1 a 64 caracteres, solo `a-z 0-9 . _ + -`, sin punto al
    principio ni al final, y sin `..`.
- **Mensaje de error:** "Usa tu correo institucional de la UTB (termina en @utb.edu.co)".
- **Dónde se aplica:**
  - Registro.
  - Cambio de correo.
  - Creación de cuentas por consola (`scripts/crear_admin.py --crear`).
  - Lista de asignaciones de roles.
- **Olvidé mi contraseña.** Solo se valida el formato. La respuesta es la misma exista o no la
  cuenta. Una cuenta **antigua** con otro dominio sigue pudiendo recuperar su clave: no se
  bloquea a nadie.
- **Inicio de sesión:** sin cambios. Las cuentas existentes con otro dominio siguen entrando.
  `GET /auth/me` devuelve `correo_institucional: false` y el perfil les pide pasarse al correo
  institucional, que se confirma con un enlace enviado al correo nuevo.
- **Desarrollo y pruebas.** Se puede ampliar la lista
  (`DOMINIOS_PERMITIDOS=utb.edu.co,example.com`; en la app,
  `--dart-define=DOMINIOS_PERMITIDOS=...`). Una prueba garantiza que sin configuración se
  rechaza `gmail.com`. Si producción amplía la lista, el arranque lo avisa en el log.

### 2. El rol sale de una lista que mantiene el administrador, y solo con el correo comprobado

- **Tabla `asignaciones_rol`.** Guarda el correo exacto, el rol, un cargo opcional, quién la
  creó y cuándo. No admite comodines ni patrones. El correo debe cumplir la regla del punto 1.
- **Una sola función decide el rol:** `rol_resuelto` en `app/services/asignaciones.py`.
  - Si el rol es **manual**, gana siempre.
  - Si el correo **no está comprobado**, el rol es el base: `usuario_utb`, que se muestra como
    "Estudiante".
  - Si no, se usa el rol de la asignación, o el base si el correo no tiene asignación.
- **Qué cuenta como "correo comprobado":** `email_verificado` y además
  `email_verificado_en`. Es decir, la persona abrió un enlace o usó un código que llegó a ese
  correo (verificación, recuperación o cambio de correo). Una cuenta que nació "verificada" sin
  correo real **no sube de rol**. Así, mientras no haya correo real, la lista no le da un rol
  alto a quien se registre con el correo de otra persona: hasta entonces, los roles altos se
  dan a mano.
- **Cuándo se recalcula el rol:**
  - Al verificar el correo.
  - Al recuperar la contraseña.
  - Al confirmar un cambio de correo (con el correo nuevo).
  - Al iniciar sesión.
  - En el momento en que cambia la lista (crear, editar, quitar o importar), para la cuenta de
    ese correo.
- **Si el rol cambia:** sube `sesion_version` (las sesiones abiertas se cierran y el cambio
  aplica ya) y se registra `usuario.rol_automatico` en la bitácora.
- **Rol manual.** El cambio de rol desde Usuarios marca `usuarios.rol_manual = true`, y la
  lista ya no lo pisa. `POST /usuarios/{id}/rol/automatico` lo devuelve al modo automático.
  Ambos quedan en la bitácora.
- **El último administrador está protegido.** Quitar, editar o importar una asignación que
  dejaría el sistema sin administrador activo responde 409 y no se guarda nada.
- **Nadie elige su rol.** `UsuarioCreate` ya no tiene el campo `rol`: si un cliente lo envía,
  se ignora. El registro y el perfil no tienen selector de rol. El perfil muestra el rol como
  dato de solo lectura, con su origen ("Asignado por tu correo institucional" o "Asignado por
  un administrador") y el cargo. Si no hay asignación, explica que la persona es estudiante y
  cómo pedir el cambio.
- **Migración `a7b8c9d0e1f2`:**
  - Agrega `rol_manual` con `server_default false`.
  - Marca `rol_manual = true` a **todas** las cuentas que ya tenían un rol alto, así que nadie
    baja de rol.
  - Crea la tabla `asignaciones_rol`.
  - No cambia ningún valor guardado de `rol`.
  - El modelo hace lo mismo con un rol alto creado directamente (scripts, seed, pruebas): nace
    como manual.
- **Gestión (solo el permiso `usuarios.gestionar`):**
  - Endpoints: `GET`/`POST /usuarios/asignaciones`, `PATCH`/`DELETE
    /usuarios/asignaciones/{id}` y `POST /usuarios/asignaciones/importar`.
  - La importación recibe una lista pegada o un CSV (`correo,rol[,cargo]`, con coma o punto y
    coma). Es **todo o nada**: con un error en cualquier línea no se guarda ninguna y la
    respuesta trae los errores por línea. `simular: true` solo revisa.
  - En la bitácora, el correo va oculto (`a***@utb.edu.co`) y la importación solo guarda cifras.
  - En la app: Perfil > Administración > **Roles por correo** (buscar, agregar, editar, quitar
    e importar, revisando antes de aplicar).

### 3. Lista inicial en producción, sin datos reales en el repositorio

Hay dos opciones:

- **(a) Desde la app.** El administrador entra con su cuenta y usa Perfil > Roles por correo >
  Importar lista: pega la lista, toca Revisar y luego Aplicar.
- **(b) Por consola, en el servidor.**
  1. Se crea un archivo local, por ejemplo `privado/asignaciones.csv`. La carpeta `privado/` y
     los archivos `asignaciones*.csv` están en `.gitignore`.
  2. Se ejecuta `python scripts/cargar_asignaciones.py privado/asignaciones.csv`. El script
     revisa la lista, muestra los errores por línea y pregunta antes de aplicar.
  3. En la bitácora queda registrado con origen "consola".
- **Las contraseñas nunca van en la lista.** El primer administrador sigue creándose con
  `scripts/crear_admin.py`, que pide la clave por consola.

## Consecuencias

- **Positivas:**
  - Solo entran correos de la UTB y el rol no depende de lo que diga el cliente.
  - Un rol alto exige que alguien lo autorice (la lista o un administrador) **y** que la persona
    demuestre que el correo es suyo.
  - Nadie pierde su rol ni su acceso con la migración.
- **Negativas:**
  - Alguien tiene que mantener la lista.
  - Mientras no haya correo real en producción, la lista no da roles altos a cuentas nuevas
    (tienen que asignarse a mano). Esto es a propósito.
- **APK instaladas:**
  - Siguen funcionando: el valor de `rol` no cambió y las respuestas solo agregan campos
    (`correo_institucional`, `rol_origen`, `rol_origen_texto`, `cargo`, `rol_manual`).
  - Una APK vieja que envíe `rol` en el registro no se ve afectada, porque el campo se ignora.
  - Con una APK vieja, un registro con Gmail ahora recibe el mensaje del servidor en español.
- **Descartado:**
  - Deducir el rol por el formato del correo (no es confiable).
  - Reglas con comodines como `*@utb.edu.co`: le darían un rol alto a todo el dominio.
  - Admitir subdominios automáticamente: abre la puerta a dominios parecidos.
  - Bloquear las cuentas existentes con otro dominio: el requisito pide no bloquearlas.

## Pruebas

- `tests/test_correo_institucional.py`: casos tramposos, Gmail rechazado sin configuración,
  cuentas antiguas que siguen entrando y cambio de correo.
- `tests/test_rol_por_correo.py`: rol base, rol asignado tras verificar, rol manual, cambios de
  la lista auditados con sesiones invalidadas, último administrador, importación y script de
  consola.
- `tests/test_matriz_permisos.py`: las filas nuevas de la matriz.
- En la app: `frontend/test/correo_institucional_test.dart`, `asignaciones_test.dart` y
  `perfil_foto_test.dart`.
