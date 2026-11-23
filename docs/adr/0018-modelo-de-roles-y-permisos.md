# 0018 - Modelo de roles y permisos con una matriz única

## Estado

Aceptado (2026-11-15). Completa ADR-0008 (control de acceso granular): la autorización ya no
compara textos de rol en cada router, sino permisos de una tabla única.

> **Nota (2026-11-21, ADR-0024):** los roles siguen igual en esta fase; el rediseño por funciones (Docente, Operador de salones, Auditor de solo lectura, alcance y matriz en un archivo de datos) continúa en las fases siguientes de ADR-0024. La carga de roles ya no es automática.

> **Nota (2026-11-21, ADR-0025):** la tabla rol → permisos pasó a `app/middleware/matriz_permisos.json`; la app ya no tiene copia y recibe los roles en `GET /auth/roles`.

## Contexto

La app tenía tres valores de rol (`usuario_utb`, `auxiliar`, `administrador`), pero las reglas
estaban repartidas:

- **Backend:** cada router repetía listas de roles (`require_role("administrador", "auxiliar")`)
  o comparaba `current_user.rol` a mano.
- **Inventario automático:** encontró huecos.
  - El **auxiliar** podía listar todas las cuentas, cambiar roles y desactivar usuarios.
  - Cualquier usuario podía ver el correo de cualquier otro (`GET /auth/user/{id}`, T-03).
  - Cualquiera podía prestar o devolver equipos por el endpoint legado (T-04, T-06), y eso
    contradice ADR-0010: los equipos son fijos y no se prestan.
  - Cualquiera podía ver el historial de mantenimiento, los indicadores operativos y los
    reportes de cualquier salón.
- **App:** usaba `esAdministrador`, que trataba igual al auxiliar y al administrador, así que
  el auxiliar veía la gestión de usuarios.

El negocio define tres roles:

1. **Estudiante:** solicita salones eligiéndolos por tipo y equipamiento.
2. **Auditor:** administra todos los salones (solicitudes, presencia, reportes, equipos,
   horarios).
3. **Administrador:** es el equipo. Puede todo lo anterior y además gestiona usuarios, ve la
   bitácora y las estadísticas, y tiene un modo prueba.

Hay APK instaladas que leen el campo `rol` con los valores actuales, y el `.env` del servidor
no se puede editar.

## Decisión

1. **Tabla única** en `app/middleware/permisos.py` (`PERMISOS_POR_ROL`): 16 permisos con nombre de
   acción.
   - Por ejemplo: `salones.solicitar`, `solicitudes.gestionar`, `salones.administrar`,
     `usuarios.gestionar`, `auditoria.ver`, `estadisticas.ver`, `modo_prueba`.
   - Los routers piden un permiso con `require_permiso(...)` mediante alias de tipo en
     `app/middleware/deps.py` (`GestionaSolicitudes`, `GestionaUsuarios`…). No quedan listas de
     roles en los routers ni comparaciones del texto del rol fuera de esa tabla.
   - Un rol desconocido no tiene permisos: la tabla falla cerrada.
2. **La matriz es la especificación.** `docs/seguridad/matriz-permisos.md` lista cada endpoint,
   lo que exigía antes y lo que exige ahora.
   - `tests/test_matriz_permisos.py` la hace cumplir en dos niveles:
     - Lee las dependencias reales de cada ruta y las compara con la fila.
     - Llama cada endpoint con cada rol y sin sesión, y espera 401/403 o acceso.
   - Si se agrega un endpoint sin fila, la prueba falla.
3. **Etiquetas, no valores nuevos.**
   - `usuario_utb` = Estudiante, `auxiliar` = Auditor, `administrador` = Administrador.
   - El valor guardado y el que devuelve `rol` **no cambian**.
   - Se agrega `rol_etiqueta`, y `GET /auth/me` devuelve además `permisos`.
   - **Por qué no se renombró el valor:** las APK instaladas comparan esos textos. Renombrarlos
     las rompería, y exigiría una migración de datos y un despliegue coordinado de app y
     servidor que no se puede garantizar. Una etiqueta da los nombres del negocio sin ese
     riesgo.
4. **"Auditor" no es la "auditoría".** El rol Auditor administra salones. La bitácora de
   cambios (ADR-0010) se llama "Bitácora de auditoría" en la app y solo la ve el
   administrador.
5. **Seguridad de roles** (`app/service/usuarios.py`):
   - El registro público siempre crea Estudiante, aunque el cuerpo de la petición traiga otro
     rol.
   - Solo el administrador cambia roles y estados.
   - Nadie puede cambiarse el rol ni desactivarse a sí mismo desde el panel (409).
   - Nunca queda el sistema sin un administrador activo (409). Esto también aplica a
     desactivar la cuenta propia desde el perfil.
   - Cambiar el rol o el estado sube `sesion_version` (ADR-0014): las sesiones abiertas de esa
     persona dejan de valer y el cambio aplica de inmediato.
   - Todo queda en la bitácora con quién lo hizo, a quién, y el rol anterior y el nuevo con sus
     etiquetas.
6. **Administrador real sin claves en el repositorio.**
   - `scripts/crear_admin.py <correo>` promueve una cuenta existente, o la crea con `--crear`.
     La contraseña se pide por consola con `getpass`.
   - El seed de demostración se niega a correr con `ENVIRONMENT=production`.
   - Las claves de demostración están **solo** en `scripts/seed_demo.py`.
7. **Modo prueba solo de interfaz.**
   - El administrador elige "ver como" Estudiante o Auditor en Perfil.
   - La app dibuja la navegación de ese rol (`Permisos.deRol`), con una franja visible
     "Viendo como … · Salir".
   - Se guarda solo en el dispositivo (`flutter_secure_storage`): no se envía al servidor ni se
     registra en la bitácora.
   - El servidor sigue aplicando el rol real. Para comprobar lo que un rol **no** puede hacer,
     se entra con su cuenta demo.
8. **La app decide por permisos.** Una sola clase `Permisos` en el cliente, espejo de la
   tabla.
   - La barra inferior se arma con `pestanasPara(permisos)`.
   - Ante un 403, una ruta sin permiso o un rol que cambió con la app abierta, se muestra
     "No tienes acceso a esto" (`SinAcceso`, `ConPermiso`) y se vuelve a leer el perfil.
9. **Solicitudes con respuesta.**
   - Migración `f6a7b8c9d0e1`: `respuesta`, `atendido_por_id` y `atendido_en` en
     `prestamos_salon`, todas opcionales.
   - Endpoints nuevos:
     - `GET /prestamos-salon/mias`.
     - `GET /prestamos-salon/gestion`: muestra el conflicto con otra solicitud aprobada o con
       una clase, calculado con dos consultas por página.
     - `POST /prestamos-salon/{id}/aprobar`, con nota opcional. Devuelve 409 si hay conflicto.
     - `POST /prestamos-salon/{id}/rechazar`, con motivo obligatorio.
   - Al responder se envía un correo al estudiante por el outbox (plantilla
     `solicitud_salon_respuesta`, categoría "salones", que respeta sus preferencias).
   - El `PATCH` anterior sigue funcionando sin `respuesta`, porque la APK instalada lo usa así.
   - Push: no se agregó. FCM necesita credenciales que el servidor no tiene. La app muestra el
     aviso en el Inicio del estudiante.
10. **Pantallas y endpoints del administrador:**
    - `GET /usuarios`: búsqueda, filtro por rol y última actividad, sacada de una subconsulta
      agrupada de la bitácora.
    - `PATCH /usuarios/{id}/rol` y `PATCH /usuarios/{id}/estado`.
    - `GET /stats/admin`: estadísticas de usuarios, solicitudes, salones y reportes, con una
      consulta agrupada por bloque.
    - En la bitácora: filtro por acción y exportación a CSV copiada al portapapeles, porque
      no hay paquete para guardar archivos.

Decisiones tomadas sin consulta (la opción más segura y compatible):

- El estudiante **sí** puede reportar un problema de un salón o equipo.
- El auditor y el administrador también pueden solicitar salones, como antes.
- `/stats/resumen` pasa a `salones.administrar`: son indicadores operativos y la app no los
  usaba con estudiantes.
- El préstamo de equipos legado (`/prestamos`) queda solo para auditor y administrador, por
  compatibilidad del contrato.
- Las columnas nuevas no tienen restricción de clave foránea en la base, porque SQLite no
  permite agregarla con `ALTER TABLE`. La relación la declara el modelo.

## Alternativas consideradas

- **Renombrar los valores guardados** (`estudiante`, `auditor`): descartada. Rompe las APK
  instaladas (punto 3).
- **Permisos por usuario en la base** (tabla de permisos editable): más flexible, pero el
  negocio tiene tres roles fijos. Una tabla en código se prueba y se revisa en el PR.
- **Modo prueba en el servidor** (suplantar al otro rol en la API): daría un "probar de verdad"
  más fiel, pero un administrador con permisos reducidos en el servidor es una fuente de
  errores y de abuso. Para la prueba real están las cuentas demo.
- **Esconder botones solo en la app:** descartada. La regla tiene que estar en el servidor; la
  app solo refleja lo que el servidor permite.

## Consecuencias

- **Positivas:**
  - Un solo lugar que cambiar.
  - Una prueba que impide endpoints sin regla.
  - Se corrigieron 11 endpoints con acceso de más (marcados ⚠ en la matriz). T-03 y T-04
    quedan mitigados y T-06, parcial.
  - Cada rol tiene su navegación.
  - Las APK instaladas siguen funcionando: `rol` igual y solo campos añadidos (prueba de
    contrato contra el `openapi.json` anterior).
- **Negativas:**
  - Un auditor que use una APK anterior ve el panel de usuarios, pero recibe "No tienes
    permiso". La APK anterior lo llama "Auxiliar de planta".
  - La tabla está duplicada en el cliente (`Permisos.deRol`), solo para servidores antiguos y
    el modo prueba. La prueba `roles_test.dart` verifica los tamaños por rol.
  - El modo prueba no demuestra un 403: eso se prueba con las cuentas demo.

## Trazabilidad

| Decisión | Código | Pruebas |
|---|---|---|
| Tabla única y dependencias | `app/middleware/permisos.py`, `app/middleware/deps.py` | `tests/test_matriz_permisos.py` (290 casos: endpoint × rol × sin sesión) |
| `/auth/me` con permisos y etiqueta | `app/schemas/perfil.py`, `app/schemas/auth.py` | `tests/test_roles.py::test_me_devuelve_etiqueta_y_permisos_de_cada_rol` |
| Reglas de roles | `app/service/usuarios.py`, `app/service/perfil.py::desactivar_cuenta`, `app/handler/usuarios.py` | `test_solo_el_administrador_cambia_roles`, `test_cambio_de_rol_invalida_las_sesiones_y_queda_auditado`, `test_no_se_degrada_ni_desactiva_al_ultimo_administrador_ni_a_uno_mismo`, `test_desactivar_y_reactivar_usuario` |
| Administrador real | `scripts/crear_admin.py`, `scripts/seed_demo.py` | `test_crear_admin_promueve_por_consola_sin_clave_en_argumentos`, `test_crear_admin_crea_la_cuenta_pidiendo_la_clave` |
| Solicitudes con respuesta | `app/service/prestamos_salon.py`, `app/handler/prestamos_salon.py`, migración `f6a7b8c9d0e1`, `app/service/plantillas_correo.py` | `test_rechazar_exige_motivo_y_avisa_al_estudiante`, `test_la_bandeja_muestra_el_conflicto_y_no_deja_aprobarlo`, `test_la_bandeja_no_hace_una_consulta_por_solicitud`, `test_patch_legado_sigue_funcionando_sin_respuesta` |
| Estadísticas | `app/service/estadisticas.py`, `app/handler/stats.py` | `test_estadisticas_del_administrador_con_datos_reales` |
| App por permisos | `frontend/lib/features/auth/domain/permisos.dart`, `frontend/lib/features/home/presentation/shell_page.dart`, `frontend/lib/shared/sin_acceso.dart` | `frontend/test/roles_test.dart` |
| Modo prueba | `frontend/lib/features/auth/presentation/auth_controller.dart` (`verComo`), `cuenta_page.dart` | `roles_test.dart` (grupo "Modo prueba") |
| Pantallas nuevas | `frontend/lib/features/solicitudes/`, `frontend/lib/features/admin/`, `frontend/lib/features/auditoria/` | `roles_test.dart` (360 dp, texto grande) |
