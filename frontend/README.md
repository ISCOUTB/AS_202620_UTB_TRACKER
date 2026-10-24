# UTB Tracker — app móvil (Flutter)

Cliente del API FastAPI de este repositorio (contenedor "App Móvil" del C4 nivel 2).
Interfaz oscura con buscador, accesos rápidos por categoría, tarjetas y barra inferior en píldora.

## Cómo correrla

El repositorio trae solo el código Dart y las figuras. Las carpetas de plataforma (`android/`, `ios/`, `web/`)
las genera Flutter una vez, sin tocar `lib/` ni `pubspec.yaml`:

```bash
cd frontend
flutter create . --org co.edu.utb --project-name utb_tracker_app   # solo la primera vez
flutter pub get
flutter test
flutter run
```

Backend en otra terminal (desde la raíz del repo): `./run.sh`

### Dirección del API ("el laberinto de la red local", Blueprint)

| Cliente | Dirección que usa la app |
|---|---|
| Servidor Producción (nube) | `https://129-80-171-141.nip.io` |
| Simulador iOS local | `http://127.0.0.1:8000` |
| Emulador Android local | `http://10.0.2.2:8000` |
| Celular real en LAN local | `flutter run --dart-define=API_BASE_URL=http://<IP-de-tu-PC>:8000` |
| Flutter Web local | `http://127.0.0.1:8000` |

Android bloquea HTTP sin cifrar desde la API 28: para desarrollo agrega
`android:usesCleartextTraffic="true"` en `<application>` de `android/app/src/main/AndroidManifest.xml`.

### Banderas útiles

- `--dart-define=API_BASE_URL=...` cambia el servidor.
- `--dart-define=PERMITIR_ELEGIR_ROL=false` oculta el selector de rol en el registro (usar cuando se cierre la brecha B-5).

## Figuras

Todas las ilustraciones están en **`assets/figuras/`** (SVG) y se referencian solo desde
`lib/core/assets/figuras.dart`. Para cambiar una figura basta reemplazar el archivo con el mismo nombre.
Se dibujan con `flutter_svg`, la única dependencia que no aparece en el Blueprint del curso: si el profesor
no la aprueba, se convierten a PNG y se cambia `SvgPicture.asset` por `Image.asset` en `shared/widgets.dart`.

## Arquitectura (Clean Architecture, Blueprint FastAPI + Flutter)

```
lib/
  core/        ApiClient (el "puente"), errores, tema, config, DI con GetIt, utilidades
  features/
    auth/      login · registro · sesión           (domain / data / presentation)
    recursos/  catálogo, filtros, detalle, alta    (domain / data / presentation)
    prestamos/ solicitar préstamo, actividad       (domain / data / presentation)
    home/      inicio y barra inferior
    cuenta/    perfil y cierre de sesión
  shared/      widgets reutilizables
```

La dependencia apunta al centro: la presentación usa repositorios (interfaces de `domain/`); solo `data/`
conoce JSON y HTTP. Estado con `ChangeNotifier` + `ListenableBuilder`, sin paquetes extra.

## Qué usa del backend

`POST /auth/login`, `POST /auth/register`, `GET /auth/user/{id}`, `GET /salud`,
`GET|POST /recursos`, `GET /recursos/{id}`, `GET|POST /prestamos` (con `X-Idempotency-Key`).

Lo que el backend aún no ofrece (devolución, cambio de estado/daño, token obligatorio, filtros por usuario,
notificaciones…) está en [`../docs/brechas_backend.md`](../docs/brechas_backend.md). La app trae rodeos
documentados para B-1, B-7 y B-5, y no inventa endpoints.
