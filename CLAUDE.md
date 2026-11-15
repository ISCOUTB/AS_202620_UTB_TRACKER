# UTB Tracker — mapa para Claude Code

Administración de **salones** de la UTB: ocupación en vivo, solicitudes de salón, control del
auxiliar, equipos fijos por salón (NO se prestan, ADR-0010), auditoría, cuentas con correo
verificado y perfil. Backend FastAPI + app Flutter. Todo en **español** (código, UI, docs).

El dueño (Mateo) no programa: explicar en lenguaje simple y con pasos copiables.

## Backend (`app/`) — 4 capas: routers → services → schemas → models

- `core/`: `config.py` (variables de entorno y reglas de producción), `security.py` (JWT:
  `sub` = id, `sv` = versión de sesión, tokens de propósito con `jti`), `deps.py`
  (`CurrentUser`, `VerifiedUser`, `AdminUser`…), `politica.py` (contraseña ≥ 8, correo;
  espejo en `frontend/lib/core/utils/politica.dart`), `database.py`, `resilience.py`.
- `routers/` (registro en `main.py`; rutas FIJAS antes de `/{id}`): `auth` (registro, login,
  `/auth/me`, correo, contraseña), `salones` + `salones_admin` (ocupación, presencia,
  reportes), `horarios`, `prestamos_salon` (solicitudes de salón), `resources` (equipos),
  `maintenance`, `loans` (legado), `auditoria`, `stats`, `health` (`/salud`).
- `services/`: lógica. `auth.py`, `perfil.py`, `correo.py` + `plantillas_correo.py` +
  `paginas_auth.py` (correos y páginas HTML de los enlaces), `limites.py` (límites en BD),
  `equipamiento.py` (equipamiento calculado con UNA consulta agrupada), `salones*.py`,
  `auditoria.py` (llamar `auditoria.registrar(..., actor_id=...)` en acciones sensibles).
- `models/`: `auth_models` (Usuario), `salon_models` (Salon, Horario, PrestamoSalon…),
  `recurso_models`, `seguridad_models` (TokenUsado, IntentoLimitado), `auditoria_models`.
- `messaging/`: outbox transaccional + `worker.py` (`python -m app.messaging`): envía correos
  (`correo.enviar`) y push, respeta preferencias salvo correos de seguridad.
- Horas: horarios en UTC-5; préstamos en UTC "naive".

## App Flutter (`frontend/lib/`) — por feature: `data/` `domain/` `presentation/`

- `core/`: `config/api_config.dart` (servidor; por defecto la nube), `network/api_client.dart`
  (refresco del token ante 401), `di/injection.dart` (GetIt), `theme/app_theme.dart`
  (**solo `AppColors`**), `theme/escala.dart` (escala 1,10 y tamaño de texto),
  `storage/token_storage.dart`.
- `features/`: `auth` (login, verificación, cambiar correo), `cuenta` (perfil), `home`
  (shell/inicio), `salones` (usuario), `salones_admin` (panel y control del auxiliar),
  `control`, `recursos`, `admin`, `auditoria`, `stats`, `prestamos`.
- `shared/`: `utb_ui.dart` (identidad visual), `widgets.dart`, `equipamiento_chips.dart`,
  `servidor.dart` (insignia del servidor).
- Sin paquetes nuevos de pub sin preguntar. Paleta y logo fijos (ADR-0011/0013).

## Base de datos y migraciones

- Alembic, una sola cabeza (`alembic heads`). NUNCA reescribir migraciones ya desplegadas;
  crear una nueva. Columnas nuevas con `server_default` (el servidor viejo sigue corriendo
  durante el despliegue). Probar en PostgreSQL además de SQLite.
- `scripts/preparar_bd.py`: actualiza una base local sin borrar datos.
- `scripts/seed_demo.py`: datos de ejemplo (repetible). Cuentas demo en `docs/COMO_EJECUTAR.md`.

## Comandos (PowerShell, desde la raíz)

```powershell
.\iniciar.ps1                                   # API + worker + app web locales (-Nube, -SinCompilar)
.\detener.ps1
.\venv\Scripts\python -m pytest tests -q        # backend (~5 min, SQLite)
cd frontend; flutter analyze; flutter test      # app
$env:JAVA_HOME="C:\Program Files\Android\Android Studio\jbr"; cd frontend; flutter build apk --release
```

PostgreSQL para pruebas: hay un PostgreSQL 18 instalado; crear uno temporal con `initdb`
en el scratchpad (puerto 5499, `-A trust`) y usar `TEST_DATABASE_URL`/`DATABASE_URL`.

## Despliegue

- Servidor oficial `https://129-80-171-141.nip.io` (APK y `iniciar.ps1 -Nube`). Solo
  lecturas (`/salud`, `/docs`, `/openapi.json`); no crear cuentas ni enviar correos allí.
- Unir a `main` dispara `.github/workflows/ci.yml`: pytest en PostgreSQL → SSH → `alembic
  upgrade head` → reinicia servicios. Estado: API pública de GitHub Actions.
- SonarCloud revisa cada PR (calidad y seguridad); consultar con
  `https://sonarcloud.io/api/issues/search?componentKeys=ISCOUTB_AS_202620_UTB_TRACKER&pullRequest=N`.
- No se puede hacer push desde Claude (permiso bloqueado): Mateo sube con GitHub Desktop.
- El APK NO se actualiza solo: cambios de pantallas requieren compilar e instalar uno nuevo;
  copia en `C:\Users\Mateo\Desktop\UTB-Tracker.apk`.
- Correo real pendiente: sin `USE_REAL_MAIL=true` las cuentas nuevas nacen verificadas
  (`VERIFICACION_OBLIGATORIA`, ADR-0014 punto 11). Guía: `docs/despliegue/worker.md`.

## Reglas del curso (cada cambio)

Mantener coherencia, correspondencia y trazabilidad: ADR nuevo o nota en uno existente
(`docs/adr/`), `docs/arc42/arc42.md` (§5 bloques, §9 decisiones), `docs/aspectos.md`,
`docs/seguridad/`, y una fila en `docs/ia.md` por cada trabajo hecho con IA.

## Ahorro de tokens

- Empezar por este mapa y abrir solo el archivo indicado. Para "dónde está X" usar Grep.
- Grafo: `graphify query "<pregunta>" --budget 800` para preguntas que crucen backend, app y
  docs; `graphify explain "<símbolo>"` para quién usa algo. Resumen en
  `graphify-out/GRAPH_REPORT.md` (leer por secciones). Se reconstruye solo en cada commit
  (hook); a mano: `graphify update .`. Ruido excluido en `.graphifyignore`.
- No leer enteros: `docs/contracts/openapi.json` (160 KB, se regenera desde la app; lo
  valida `tests/test_contract.py`), `docs/arc42/arc42.md` (50 KB), `docs/seguridad/
  modelo-amenazas.md` (36 KB), `docs/ia.md` (agregar al final), `requirements.txt` (hashes).
  Usar Grep por título o ID (QS-04, T-23, ADR-0014…).
- Pruebas: correr solo el archivo afectado (`pytest tests/test_x.py -q`) mientras se trabaja;
  la suite completa al final.
