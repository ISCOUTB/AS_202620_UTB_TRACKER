# 0025 - La matriz de permisos vive en un solo archivo de datos (Fase 2 del rediseño de roles)

## Estado

Aceptado (2026-11-21). Completa ADR-0018 (modelo de roles y permisos) y ADR-0024 (Fase 1).

## Contexto

- La tabla "rol → permisos" estaba escrita dos veces: `app/middleware/permisos.py` y
  `frontend/lib/features/auth/domain/permisos.dart`, más una tercera en
  `docs/seguridad/matriz-permisos.md`. Había que mantenerlas iguales a mano.
- La copia de la app solo servía con servidores anteriores a ADR-0018 y para el modo prueba del
  administrador.

## Decisión

1. **Una sola fuente:** `app/middleware/matriz_permisos.json` (roles, etiqueta, descripción y la lista
   de permisos de cada rol). Es el único archivo que se edita para cambiar qué puede hacer cada
   rol. Los valores de rol son los guardados en la base.
2. **El backend la carga y la valida al arrancar** (`app/middleware/permisos.py`): los roles del archivo
   son exactamente los del enum `Rol` y cada permiso nombrado existe en `Permiso`. Si no cuadra,
   la API no arranca. El enum `Permiso` sigue siendo la lista de nombres que usan los routers.
3. **La app no tiene copia.** Recibe los permisos reales en `GET /auth/me` (`permisos`) y el
   catálogo de roles (etiqueta, descripción y permisos) en el endpoint nuevo `GET /auth/roles`
   (solo sesión). Se eliminó `Permisos.deRol` y los conjuntos fijos; la app solo pregunta
   `puede(permiso)`. El modo prueba y la lista de roles de Usuarios salen de `GET /auth/roles`.
   Sin lista del servidor no hay permisos (falla cerrado).
4. **La documentación se valida contra la fuente:** `tests/test_matriz_unica.py` compara la tabla
   "Permisos por rol" de `docs/seguridad/matriz-permisos.md` con el JSON, comprueba que todo
   permiso del código lo tiene algún rol, que `/auth/roles` y `/auth/me` devuelven lo del
   archivo y que ningún `.dart` reconstruye la tabla. Un endpoint nuevo sin fila sigue haciendo
   fallar `tests/test_matriz_permisos.py`.

## Consecuencias

- Cambiar un permiso de un rol es editar una línea del JSON (y la fila de la documentación; si
  no, la prueba falla). Ya no hay que acordarse de la app.
- Una APK vieja que traiga su propia tabla sigue funcionando con `permisos` de `/auth/me`
  (se rompió la compatibilidad de todos modos en ADR-0024: hay que instalar la APK nueva).
- Prepara las fases siguientes: roles por función (Docente, Operador de salones, Auditor de solo
  lectura), varios roles por persona y alcance por bloque se agregan en este mismo archivo.
- El archivo viaja dentro de `app/`: no necesita configuración en el servidor.

## Anexo: un correo = una cuenta (2026-11-21)

Al verificar que no se pueden crear varias cuentas con el mismo correo (mismo correo, mayúsculas,
espacios, cambio de correo, índice único de la base y carrera de dos registros: todo da 409) se
encontró que los alias con `+` (`ana+2@utb.edu.co`) llegan al mismo buzón que `ana@utb.edu.co` y
creaban otra cuenta. Decisión del dueño: **se rechazan en registros y cambios de correo nuevos**
(`error_correo_nuevo` y su espejo `politica.dart`, mensaje "sin alias"). Las cuentas que ya existían
con `+` siguen entrando; un administrador les asigna rol desde la pantalla Usuarios (la carga
masiva usa la misma regla y las rechazaría). Pruebas: `tests/test_correo_unico.py` y
`tests/test_roles_sin_verificacion.py`.

## Pruebas

`tests/test_matriz_unica.py`, `tests/test_matriz_permisos.py`, `tests/test_contract.py`; en la app
`test/roles_test.dart` (con un catálogo falso solo de pruebas, `test/catalogo_roles_falso.dart`).
