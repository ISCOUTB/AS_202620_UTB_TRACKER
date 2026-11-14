# Identidad visual de UTB Tracker

UTB Tracker es una herramienta interna del Campus de la Universidad Tecnológica de Bolívar
(Cartagena de Indias). Su identidad hereda los **colores corporativos de la Universidad** y
usa un símbolo propio, para que se reconozca como parte de la UTB sin imitar su logosímbolo
(el aro con la palma y la tipografía Castle T-Bold son marca registrada de la Universidad y
no se reproducen aquí).

## Colores

Desde el 2026-11-13 la paleta de la app sigue la de la app oficial **UTB App** (la que usan los
estudiantes: azul real, degradado azul → índigo en los encabezados, fondo negro y tarjetas gris
carbón). Así UTB Tracker se siente parte del mismo ecosistema digital de la Universidad. Antes se
usaban el verde `#187943` y el índigo `#332D83` del *Manual de identidad UTB*
(<https://www.utb.edu.co/wp-content/uploads/2021/04/MANUAL-IDENTIDAD-UTB.pdf>); el logo conserva
esos colores.

| Rol | Nombre | HEX | Dónde se ve |
|---|---|---|---|
| Marca | **Azul UTB App** | `#2F55E4` | Botones principales, selección, chips activos |
| Marca | **Índigo** | `#4B3BDB` | Extremo final del degradado |
| Marca | Degradado de encabezado | `#1D3FE0` → `#4B3BDB` | Bloque superior de Inicio |
| Apoyo | Azul claro | `#6B93FF` | Texto, íconos y foco sobre fondo oscuro; ícono activo de la barra inferior |
| Apoyo | Índigo claro | `#A9BFFF` | Detalles secundarios |
| Apoyo | Selección | `#1E2C57` | Píldora activa de la barra inferior |
| Fondo | Fondo / superficie / superficie alta | `#000000` / `#1B1C21` / `#2A2C33` | Pantallas, tarjetas, barra inferior y hojas (gris neutro, sin tinte) |
| Borde | Borde | `#3A3D46` | Contornos de tarjetas |
| Texto | Texto / suave / tenue | `#FFFFFF` / `#C5C8D0` / `#8C9099` | Jerarquía del texto |
| Estado | Disponible / Prestado / Dañado / Mantenimiento | `#3DDC97` / `#FFB84D` / `#FF6B6B` / `#6CB4FF` | Insignias y plano de salones (semánticos: no cambian con la marca) |

Contraste (WCAG): texto blanco sobre el azul de marca ≈ 5,9:1 (cumple AA para texto normal); el
texto `#C5C8D0` sobre el fondo negro supera 12:1.

## Símbolo

`frontend/assets/figuras/logo.svg` (copia en `docs/identidad/logo.svg`; versión con nombre en
`docs/identidad/logo-horizontal.svg`).

Desde el 2026-11-14 es un **pin de ubicación blanco** sobre el degradado azul → índigo de la app
(`#1D3FE0` → `#4B3BDB`). Dentro del pin hay **un plano de cuatro salones**: tres tenues (ocupados) y
uno azul con visto (libre/confirmado). El pin dice "tracker" (saber dónde está cada cosa) y las
baldosas repiten el plano de salones de la app, así que el logo y la pantalla principal hablan el
mismo idioma. Reemplaza al cuadrado índigo con baldosa verde anterior, que no combinaba con la
paleta azul de UTB App.

Reglas de uso: no estirar, no cambiar los colores, margen libre mínimo igual al ancho de una baldosa,
y no combinarlo con el logosímbolo de la Universidad en el mismo cuerpo (la UTB va como "Campus
UTB", en texto).

## Dónde se aplica

| Pieza | Archivo |
|---|---|
| Paleta y tema de la app | `frontend/lib/core/theme/app_theme.dart` |
| Logo en la app | `frontend/assets/figuras/logo.svg` |
| Iconos web / PWA y favicon | `frontend/web/icons/`, `frontend/web/favicon.png`, `frontend/web/manifest.json` |
| Fuentes del ícono | `frontend/assets/icono/icono_cuadrado.svg` (ícono completo) y `primer_plano.svg` (solo el pin, para el ícono adaptativo) |
| Icono de Android | `frontend/android/app/src/main/res/mipmap-*/ic_launcher.png` y el adaptativo en `mipmap-anydpi-v26/` (pin sobre fondo `#2F55E4`) |
| Pantalla de arranque (splash) | `drawable*/`, `values-v31/` (Android 12+) y `frontend/web/splash/`: logo sobre fondo negro |

Los PNG de `frontend/assets/icono/` se generan desde los SVG. Si cambia el logo, se regeneran esos
PNG y luego los íconos y el splash con:

```powershell
cd frontend
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

(la configuración está en `frontend/pubspec.yaml`, secciones `flutter_launcher_icons` y `flutter_native_splash`).

## Lenguaje visual (ADR-0011)

Las piezas viven en `frontend/lib/shared/utb_ui.dart` y se inspiran en la app oficial UTB App:

| Pieza | Uso |
|---|---|
| `EncabezadoDegradado` | Bloque superior de cada pestaña: degradado azul → índigo, arcos finos y esquinas inferiores redondeadas |
| `TarjetaDestacada` | Lo más importante del momento ("Ahora en el campus"), con barra de color de estado y dato grande |
| `TarjetaPromo` | Accesos en degradado con ícono grande de fondo (Inventario, Solicita un salón) |
| `PildoraSegmentada` | Control segmentado (Solicitudes · Reportes) con la opción activa deslizándose |
| `FilaLineaTiempo` | Clases en curso, reportes y auditoría como línea de tiempo con nodos luminosos |
| `Indicador` | Números del resumen con degradado del color de su estado |
| `Aparecer` | Entrada escalonada (desvanecer + subir) de los elementos de una lista |
| Credencial (Perfil) | Tarjeta clara tipo carnet con iniciales, nombre, correo y franja del rol |

Reglas: nada de colores planos en superficies grandes (fondo con brillos difuminados, tarjetas
"de vidrio" con degradado sutil); transiciones de 250–420 ms con `easeOutCubic`; el color de
estado nunca va solo, siempre con texto.

## Tono

Directo y breve, en español, sin tecnicismos: "Libre ahora", "Profesor sin confirmar", "Por atender".
