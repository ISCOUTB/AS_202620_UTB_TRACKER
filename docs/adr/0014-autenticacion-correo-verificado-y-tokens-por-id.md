# 0014 - Autenticación con correo verificado, identidad normalizada y tokens por id

## Estado

Aceptado (2026-11-14). Complementa ADR-0004 (JWT) y ADR-0013 (servidor único).

## Contexto

Los usuarios reportaban que "las cuentas nunca se guardan". Se reprodujo con un script contra una
API local (registro → login → reinicio de la API → login → tabla `usuarios`) y se descartaron o
confirmaron hipótesis con evidencia:

| Hipótesis | Resultado |
|---|---|
| La app y la API apuntan a servidores distintos | **Cierta**: el APK usaba la nube y la web de `iniciar.ps1` una API local, y la app no decía a cuál hablaba |
| `-ReiniciarDatos` borra cuentas | Falsa: el seed solo borra salones/recursos `DEMO-*` |
| La base no persiste | Falsa en local (la cuenta sigue tras reiniciar). En producción solo se pudo leer `/salud` |
| El registro falla y se oculta | Parcial: contraseña mínima 6 en el backend y 8 en la app; `create_user` convertía cualquier error en 500 |
| Correo con mayúsculas/espacios | **Cierta**: `"Ana@UTB.edu.co "` se guardaba tal cual, `ana@utb.edu.co` creaba otra cuenta y entrar con el correo daba 401 |
| Sesión | **Cierta**: el access token dura 60 min y la app no guardaba ni usaba el refresh token |

Además nada comprobaba que el correo fuera de quien se registraba, y el JWT usaba el correo
como `sub`, así que cambiar el correo rompería las sesiones abiertas.

## Decisión

1. **Identidad normalizada.** El correo se guarda en minúsculas y sin espacios y es único sin
   distinguir mayúsculas también en la base (índice `uq_usuarios_email_lower` sobre
   `lower(email)`, migración `b2c3d4e5f6a7`). La migración normaliza los correos existentes; si
   dos cuentas chocan, la más antigua conserva el correo y las demás pasan a
   `usuario+duplicado<id>@dominio` (no se borra ninguna).
2. **Login con nombre de usuario O correo** en el mismo campo (`nombre`, por compatibilidad con
   el contrato). El error es idéntico exista o no la cuenta.
3. **Una sola política de contraseña** (`app/core/politica.py` ↔ `frontend/lib/core/utils/politica.dart`):
   mínimo 8 caracteres, distinta del correo, de su parte local y del nombre; mismos mensajes.
   Los 422 se devuelven en español con la forma estándar de FastAPI.
4. **Correo verificado.** Columnas `email_verificado` y `email_verificado_en` (migración
   `c3d4e5f6a7b8`). Las cuentas **existentes quedan verificadas** para no dejar fuera a quien ya
   usa el sistema; las nuevas nacen sin verificar.
   - **Qué puede hacer una cuenta sin verificar:** entrar y consultar todo lo que su rol permite,
     pero **no solicitar salones** (`POST /prestamos-salon` responde 403 con instrucciones). La
     app muestra "Revisa tu correo" tras registrarse y un aviso fijo con "Reenviar".
   - Abrir el enlace de recuperación de contraseña también verifica el correo (demuestra poseerlo).
5. **Tokens de un solo uso** (verificar correo, recuperar contraseña, cambiar correo): JWT con
   claim `proposito`, `jti` aleatorio y vencimiento corto (24 h, 30 min y 24 h). Cada propósito
   se firma con un secreto distinto (`EMAIL_TOKEN_SECRET_KEY` derivado por propósito y
   `FORGET_PWD_SECRET_KEY`): uno de verificación no sirve para recuperar ni para iniciar sesión.
   Al usarlos se anota el `jti` en `tokens_usados`; un segundo uso responde 400.
6. **Sesión por id.** `sub` = id del usuario y `sv` = versión de sesión. Los tokens viejos con
   correo en `sub` se aceptan mientras vivan (como máximo `REFRESH_TOKEN_EXPIRE_DAYS`). Al
   refrescar se emite el par nuevo por id.
7. **Límites de frecuencia en la base** (`intentos_limitados`): login fallido (5 cada 5 min por
   IP+identificador) y endpoints que envían correo (3 cada 15 min por cuenta/correo y por IP). El
   diccionario en memoria se perdía al reiniciar y no servía con varios procesos.
8. **Alerta de inicio de sesión sospechoso**: si se entra tras 3 o más fallos sobre esa cuenta,
   se envía un aviso por correo.
9. **App:** guarda access + refresh; ante un 401 renueva el token UNA vez y repite la petición
   (`ApiClient`); si el refresh también es rechazado, cierra la sesión con "Tu sesión venció".
   La app muestra siempre a qué servidor habla (`InsigniaServidor`) y en compilaciones de
   desarrollo deja cambiarlo. `iniciar.ps1` levanta API + worker + app apuntándose entre sí;
   `-Nube` usa el servidor **oficial** `https://api.iscoutb.dev`.
10. **Base local que se actualiza sola:** `scripts/preparar_bd.py` detecta hasta qué migración
    llega una base creada con `create_all`, la marca y aplica las que faltan.
11. **Despliegue sin romper el servidor actual** (el `.env` del servidor no se puede editar
    desde el repositorio):
    - Sin `EMAIL_TOKEN_SECRET_KEY`, se **deriva** de `SECRET_KEY` con HMAC-SHA256 y una
      etiqueta fija: sigue siendo secreta y distinta de las demás claves.
    - Sin `URL_PUBLICA`, en producción o con correo real se usa el servidor oficial.
    - `VERIFICACION_OBLIGATORIA` vale por defecto lo mismo que `USE_REAL_MAIL`. Sin correo real,
      el enlace nunca llegaría, así que la cuenta nueva **nace verificada** (igual que las que
      existían antes) y no se encola el correo. `iniciar.ps1`, Docker Compose y las pruebas la
      ponen en `true` para usar el correo de desarrollo. Al configurar SMTP en el servidor se
      activa sola.

Valores por defecto elegidos sin consulta (propuestos en el pedido): mínimo 8, sin verificar
puede entrar pero no solicitar salones, enlaces de 24 h / 30 min.

## Alternativas consideradas

- **Bloquear el login hasta verificar:** más estricto, pero deja fuera a quien escribió mal el
  correo y no puede ni corregirlo. Se prefirió entrar con permisos reducidos + "Cambiar correo".
- **Tokens opacos guardados en la base** en lugar de JWT: igual de seguros, pero exigen guardar
  cada token emitido. Con JWT solo se guarda el `jti` al USARLO.
- **Reemitir tokens al cambiar el correo** en lugar de `sub` por id: rompe las sesiones en otros
  dispositivos sin necesidad.

## Consecuencias

- **Positivas:** una cuenta = un correo real; se entra con usuario o correo; las sesiones duran
  lo que el refresh (7 días) sin pedir la clave; los límites sobreviven a reinicios.
- **Negativas:** si el worker no corre, nadie recibe el correo de verificación (ver ADR-0015 y
  `docs/despliegue/worker.md`). Mientras el servidor no tenga correo real, las cuentas nuevas
  no confirman su correo (punto 11). En producción la API **no arranca** con `SECRET_KEY` o
  `FORGET_PWD_SECRET_KEY` por defecto ni con una `URL_PUBLICA` explícita que no sea https.
  Un escáner de correo que abra el enlace de verificación lo consume (verifica igual).
- **Deuda:** `tokens_usados` e `intentos_limitados` crecen; el worker purga los intentos viejos
  (`limites.purgar_viejos`), los tokens vencidos se pueden borrar por `expira_en`.

## Trazabilidad

| Decisión | Código | Pruebas |
|---|---|---|
| Correo normalizado y único | `app/core/politica.py`, `app/models/auth_models.py`, `alembic/versions/b2c3d4e5f6a7_*` | `tests/test_identidad.py` |
| Login por correo o nombre | `app/services/auth.py::login` | `tests/test_identidad.py::test_login_por_correo_y_por_nombre` |
| Verificación y permisos | `app/services/auth.py`, `app/core/deps.py::require_verified`, `app/routers/prestamos_salon.py` | `tests/test_correo_verificado.py` |
| Tokens de un solo uso | `app/core/security.py`, `app/models/seguridad_models.py` | `tests/test_correo_verificado.py::test_token_de_verificacion_no_sirve_para_otra_cosa` |
| Persistencia tras reinicio | `scripts/preparar_bd.py`, `iniciar.ps1` | `tests/test_persistencia_cuentas.py` |
| Refresco en la app | `frontend/lib/core/network/api_client.dart` | `frontend/test/sesion_test.dart` |
| Verificación en la app | `frontend/lib/features/auth/presentation/verificacion_page.dart` | `frontend/test/auth_controller_test.dart` |
