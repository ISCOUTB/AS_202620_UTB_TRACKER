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

Es un cuadrado redondeado índigo con **un plano de cuatro salones**: tres tenues (ocupados) y uno
verde con visto (confirmado). Resume el producto —saber qué salón está en qué situación— y repite la
forma de baldosa del plano de la app, así que el logo y la pantalla principal hablan el mismo idioma.

Reglas de uso: no estirar, no cambiar los colores, margen libre mínimo igual al ancho de una baldosa,
y no combinarlo con el logosímbolo de la Universidad en el mismo cuerpo (la UTB va como "Campus
UTB", en texto).

## Dónde se aplica

| Pieza | Archivo |
|---|---|
| Paleta y tema de la app | `frontend/lib/core/theme/app_theme.dart` |
| Logo en la app | `frontend/assets/figuras/logo.svg` |
| Iconos web / PWA y favicon | `frontend/web/icons/`, `frontend/web/favicon.png`, `frontend/web/manifest.json` |
| Icono de Android | `frontend/android/app/src/main/res/mipmap-*/ic_launcher.png` |

Los PNG se generan desde el SVG; si cambia el logo hay que regenerarlos.

## Tono

Directo y breve, en español, sin tecnicismos: "Libre ahora", "Profesor sin confirmar", "Por atender".
