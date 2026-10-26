# Cómo ejecutar UTB Tracker en Windows (PowerShell)

## Forma rápida (recomendada): un solo comando

En la terminal de VS Code, desde la raíz del repo:

```powershell
.\iniciar.ps1                  # libera puertos, enciende backend y app, abre el navegador
.\iniciar.ps1 -ReiniciarDatos  # igual, y recarga los datos de ejemplo (clases con la hora actual)
.\iniciar.ps1 -SinCompilar     # más rápido: no recompila la app si no cambiaste el frontend
.\detener.ps1                  # apaga todo
```

Se abren dos ventanas, "UTB Tracker - BACKEND" y "UTB Tracker - APP": **no las cierres**
mientras uses la app. La app queda en http://127.0.0.1:8080.

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

## 4. Cuentas de ejemplo (el login pide NOMBRE + clave)

| Rol | Nombre | Clave | Qué ve |
|---|---|---|---|
| administrador | `Admin Demo` | `Admin123!` | Panel de salones + gestión de usuarios y roles |
| auxiliar | `Auxiliar Demo` | `Auxiliar123!` | Panel de salones (plano, presencia del profesor, reportes) |
| auxiliar | `Auxiliar Laboratorio` | `Auxiliar123!` | Igual |
| usuario_utb | `Estudiante Demo` | `Estudiante123!` | Consulta y solicita salones, recursos, préstamos |
| usuario_utb | `Camila Rojas`, `Andres Torres`, `Valentina Diaz` | `Estudiante123!` | Igual |

## 5. Datos de ejemplo que crea `scripts/seed_demo.py`

- **8 salones** `DEMO-*` (edificios A, B y Laboratorios).
- **Clases en curso ahora** en A101, B201 y LAB1 (calculadas con la hora actual).
- **Préstamos de salón**: uno aprobado (A103), uno en uso (B202), dos pendientes (A102), uno rechazado.
- **13 recursos**: video beams, portátiles, aires, TV, audio y otros, en distintos estados
  (disponible, prestado, dañado, mantenimiento); 3 con préstamo activo y 1 ya devuelto.
- **Reportes** de salón (abiertos y resuelto) y un reporte de recurso dañado.

Las clases usan la hora de cuando corres el script: **vuelve a correrlo** (es repetible) cuando
las clases ya hayan terminado y quieras verlas en curso otra vez:

```powershell
.\venv\Scripts\python scripts\seed_demo.py
```

## 6. Pruebas

```powershell
.\venv\Scripts\python -m pytest tests/ -v          # backend
cd frontend; flutter test                          # frontend
```

## 7. Problemas comunes

| Síntoma | Solución |
|---|---|
| `python no se encontró` | Usa `py` o el `.\venv\Scripts\python` de arriba. |
| `flutter` no se reconoce | `$env:Path += ";C:\src\flutter\bin"` |
| La app no conecta / error de red | ¿Backend corriendo? ¿Pasaste `--dart-define=API_BASE_URL=http://127.0.0.1:8000`? |
| Celular real en la misma Wi-Fi | `--dart-define=API_BASE_URL=http://<IP-de-tu-PC>:8000` y permitir el puerto 8000 en el firewall. |
| Salones siempre "libres" | Las clases de ejemplo ya terminaron: corre `scripts\seed_demo.py` otra vez. |
| Un usuario nuevo registrado no ve el panel | El registro crea `usuario_utb`. Un administrador debe cambiar su rol, o usa las cuentas de arriba. |
| Empezar de cero | Detén el backend, borra `utb_tracker.db` y corre `scripts\seed_demo.py`. |
| Detener todo | `Get-Process dart,python -ErrorAction SilentlyContinue \| Stop-Process` |
