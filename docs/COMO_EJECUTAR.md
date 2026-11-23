# Cómo ejecutar UTB Tracker en Windows (PowerShell)

## Forma rápida (recomendada): un solo comando

En la terminal de VS Code, desde la raíz del repo:

```powershell
.\iniciar.ps1                  # LOCAL: API + worker de correos + app web, apuntándose entre sí
.\iniciar.ps1 -ReiniciarDatos  # igual, y recarga los datos de ejemplo
.\iniciar.ps1 -SinCompilar     # más rápido: no recompila la app si no cambiaste el frontend
.\iniciar.ps1 -Nube            # solo la app web, contra el servidor OFICIAL (el del celular)
.\detener.ps1                  # apaga todo (API, worker y app)
```

**¿Cuál servidor uso?** (ADR-0014)

| Comando | Servidor | Cuentas |
|---|---|---|
| `.\iniciar.ps1` | Local, en tu PC (`http://127.0.0.1:8000`, base `utb_tracker.db`) | De prueba (sección 4) y las que crees en tu PC |
| `.\iniciar.ps1 -Nube` y el APK | **Oficial**, `https://api.iscoutb.dev` | Las reales, iguales en el PC y el celular |

La app siempre muestra arriba a qué servidor habla ("Local (este PC) · conectado" u "Oficial
(nube) · conectado"). Tócalo para ver la dirección completa; en esta compilación también puedes
cambiarlo desde ahí.

Se abren las ventanas "UTB Tracker - API", "UTB Tracker - WORKER" y "UTB Tracker - APP": **no las
cierres** mientras uses la app. La app queda en http://127.0.0.1:8080. Al arrancar, la base local
se actualiza sola a la última versión (`scripts/preparar_bd.py`), sin borrar tus cuentas.

### Correos en local

En tu PC los correos **no se envían**: el worker los guarda completos en `logs\correos\`. Cada
correo tiene un `.html` (ábrelo con doble clic para verlo como lo vería la persona) y un `.eml`.
En la ventana del worker también aparece la línea `[correo-dev] NO enviado ... Enlace=...` con el
enlace listo para copiar en el navegador. Para enviar correos de verdad, ver
`docs/despliegue/worker.md`.

### Prueba guiada del flujo completo (local)

1. `.\iniciar.ps1` y en el navegador **Crear cuenta** (usa una contraseña de 8 o más caracteres).
2. Aparece "Revisa tu correo". Abre la carpeta `logs\correos\`, abre el `.html` más nuevo
   (`..._verificacion_...`) y toca **Confirmar mi correo**: sale "Correo verificado".
3. En la app toca **Ya lo verifiqué**. Ya puedes solicitar salones.
4. **Perfil → Seguridad → Cambiar correo**: escribe otro correo y tu contraseña. En
   `logs\correos\` aparecen dos correos: el enlace al correo nuevo y el aviso al anterior. Abre el
   enlace: "Correo actualizado". Tu sesión sigue abierta.
5. **Perfil → Seguridad → Cambiar contraseña**. Llega el aviso "Tu contraseña cambió".
6. Cierra la ventana "UTB Tracker - API" (o `.\detener.ps1`) y vuelve a correr `.\iniciar.ps1
   -SinCompilar`. Entra con el correo NUEVO y la contraseña NUEVA: la cuenta sigue ahí.

## Forma manual

Necesitas **dos terminales** abiertas en paralelo: una para el backend y otra para la app.
Todos los comandos se ejecutan desde la raíz del repositorio salvo que se indique.

## 0. Requisitos (una sola vez)

- **Python 3.12+** (`py --version`).
- **Flutter** (`flutter --version`). Si no está en el PATH, en cada terminal nueva:
  `$env:Path += ";C:\src\flutter\bin"` (o agrégalo al PATH de Windows para siempre).

## 1. Preparar el backend (una sola vez)

```powershell
py -m venv venv
.\venv\Scripts\python -m pip install -r requirements.txt
.\venv\Scripts\python scripts\seed_demo.py     # crea tablas (SQLite) + datos de ejemplo
```

Sin archivo `.env`, usa SQLite local (`utb_tracker.db`). No hace falta Postgres para probar.

## 2. Terminal 1 — Backend

```powershell
.\venv\Scripts\python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Comprueba en el navegador: http://127.0.0.1:8000/docs (Swagger).

## 3. Terminal 2 — App Flutter

Primera vez (genera carpetas de plataforma y descarga paquetes):

```powershell
cd frontend
flutter create . --org co.edu.utb --project-name utb_tracker_app --platforms=web,windows
flutter pub get
```

> `flutter create` agrega `test/widget_test.dart` de plantilla que falla: bórralo
> (`Remove-Item test\widget_test.dart`) y no commitees cambios a `analysis_options.yaml`.

Ejecutar (elige una):

```powershell
# Web en tu navegador: abre luego http://127.0.0.1:8080
flutter run -d web-server --web-port 8080 --dart-define=API_BASE_URL=http://127.0.0.1:8000

# Aplicación de escritorio Windows (requiere Visual Studio con "Desarrollo para escritorio con C++")
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000

# Edge/Chrome con ventana propia
flutter run -d edge --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Dentro de `flutter run`: `r` recarga en caliente, `R` reinicia, `q` sale. En `web-server`
los cambios se ven recargando la página (F5).

## 4. Cuentas de ejemplo (el login acepta el NOMBRE o el CORREO + clave)

Solo existen en tu PC (el seed se niega a correr en producción) y todas vienen con el correo
ya verificado. **Las claves están solo en `scripts/seed_demo.py`** (tabla `USUARIOS` al inicio)
y el script las imprime al terminar; no se copian a la documentación (ADR-0018).

| Rol (etiqueta) | Valor guardado | Nombre | Qué ve |
|---|---|---|---|
| Administrador | `administrador` | `Admin Demo` | Todo lo del Auditor + Usuarios, Estadísticas, Bitácora de auditoría y Modo prueba |
| Auditor | `auxiliar` | `Auditor Demo`, `Auditor Laboratorio` | Inicio operativo · Salones (plano) · Solicitudes (bandeja) · Control (reportes) · Equipos · Perfil |
| Estudiante | `usuario_utb` | `Estudiante Demo`, `Camila Rojas`, `Andres Torres`, `Valentina Diaz` | Inicio · Salones (tipo y equipamiento) · Solicitudes (las suyas) · Perfil |

### Prueba guiada por rol

1. Entra como **Estudiante Demo**: en Salones filtra "con video beam" y pide un salón libre.
   En Solicitudes aparece "Pendiente" con el botón Cancelar.
2. Cierra sesión y entra como **Auditor Demo**: en Solicitudes está el pedido con quién lo hizo
   (y "Choca con…" si se cruza con una clase). Recházalo: la app exige escribir el motivo.
3. Vuelve como **Estudiante Demo**: en Inicio y en Solicitudes ves "Rechazada · Motivo: …".
   En `logs\correos\` está el correo "Tu solicitud del salón … fue rechazada".
4. Como **Admin Demo**: Perfil → Usuarios y roles. No puedes cambiar tu propio rol; si cambias
   el de otra persona, su sesión se cierra. Perfil → Modo prueba → "Estudiante": aparece la
   franja "Viendo como Estudiante · Salir" y la barra de un estudiante. Es solo lo que se ve:
   para comprobar que un estudiante **no** puede algo, entra con su cuenta.

### Administrador real (servidor oficial)

En el servidor, con el `.env` cargado: `python scripts/crear_admin.py correo@utb.edu.co`
(promueve una cuenta ya registrada) o con `--crear` (la crea). La clave se escribe en la
consola y no se ve ni queda guardada en ningún archivo.

## 5. Datos de ejemplo que crea `scripts/seed_demo.py`

- **Salones del campus** (Aulas 4, Alcatraz, Laboratorios, Biblioteca), cada uno con su
  **tipo** y, varios, con **descripción** (ADR-0017):
  - `LAB-SIS1`: laboratorio de cómputo con 20 computadores.
  - `AUD-CT`: auditorio de 220 puestos con sonido y video beam.
  - `A4-301`: sala audiovisual; `ALC-201` y `BIB-SG1`: salas de reuniones.
  - `LAB-SIS2`: guardado a propósito como "aula" con 12 computadores, para ver en la app
    "Sugerido: Laboratorio de cómputo [Usar]".
- **Equipos fijos en cada salón** (no se prestan): video beams, computadores, aires, TV, audio,
  algunos dañados o en mantenimiento. El equipamiento que muestra la app se calcula de ellos.
- **Clases en curso ahora** (calculadas con la hora actual), solicitudes de salón en distintos
  estados y reportes de salón.
- Los salones `DEMO-*` de versiones anteriores se borran solos al correr el script.

Las clases usan la hora de cuando corres el script: **vuelve a correrlo** (es repetible) cuando
las clases ya hayan terminado y quieras verlas en curso otra vez:

```powershell
.\venv\Scripts\python scripts\seed_demo.py
```

## 6. Instalar la app en un celular Android (APK)

El APK ya compilado apunta al **servidor en la nube** (`https://api.iscoutb.dev`), así que en
el celular funciona con datos móviles o cualquier Wi-Fi, sin tener el PC encendido.

Para generarlo de nuevo (tarda de 10 a 30 minutos la primera vez):

```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
cd frontend
flutter build apk --release
```

Queda en `frontend\build\app\outputs\flutter-apk\app-release.apk`. Pásalo al celular (cable,
Drive o WhatsApp a ti mismo), ábrelo y acepta "instalar apps de origen desconocido".

- Para que la app use **tu PC** en vez de la nube, agrega
  `--dart-define=API_BASE_URL=http://<IP-de-tu-PC>:8000` (y el celular en la misma Wi-Fi).
  Ojo: Android bloquea `http://` sin cifrar, así que en ese caso es más fácil probar con el
  emulador o la versión web.
- No hace falta `google-services.json` para compilar: Firebase se configura desde
  `lib/firebase_options.dart`. Si el archivo existe en `frontend/android/app/`, se usa.
- Si pide licencias de Android: `flutter doctor --android-licenses` y aceptar todo con `y`.

## 7. Pruebas

```powershell
.\venv\Scripts\python -m pytest tests/ -v          # backend
cd frontend; flutter test                          # frontend
```

## 8. Problemas comunes

| Síntoma | Solución |
|---|---|
| `python no se encontró` | Usa `py` o el `.\venv\Scripts\python` de arriba. |
| `flutter` no se reconoce | `$env:Path += ";C:\src\flutter\bin"` |
| La app no conecta / error de red | ¿Backend corriendo? ¿Pasaste `--dart-define=API_BASE_URL=http://127.0.0.1:8000`? |
| Celular real en la misma Wi-Fi | `--dart-define=API_BASE_URL=http://<IP-de-tu-PC>:8000` y permitir el puerto 8000 en el firewall. |
| Salones siempre "libres" | Las clases de ejemplo ya terminaron: corre `scripts\seed_demo.py` otra vez. |
| Un usuario nuevo registrado no ve el panel | El registro siempre crea un Estudiante. Un administrador le cambia el rol en Perfil → Usuarios y roles, o usa las cuentas de arriba. |
| Empezar de cero | Detén el backend, borra `utb_tracker.db` y corre `scripts\seed_demo.py`. |
| Detener todo | `Get-Process dart,python -ErrorAction SilentlyContinue \| Stop-Process` |

## Base local desde cero (SQLite)

`alembic upgrade head` falla sobre una base SQLite vacía por una migración antigua (R-11 en
`docs/revision-app.md`). No se reescribe porque ya está desplegada. En local:

```powershell
.\venv\Scripts\python scripts\seed_demo.py     # crea las tablas (create_all) y siembra
.\venv\Scripts\alembic stamp head               # marca la base como al día
```

En PostgreSQL (producción y CI) `alembic upgrade head` funciona normal.
