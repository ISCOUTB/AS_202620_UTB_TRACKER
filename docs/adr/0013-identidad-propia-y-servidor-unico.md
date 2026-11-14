# 0013 - Identidad visual propia, interfaz más compacta y un solo servidor para todos los clientes

## Estado

Aceptado (2026-11-14). Modifica el punto 4 de ADR-0011.

## Contexto

Al probar el APK en un celular real aparecieron tres problemas:

1. **Cuentas distintas según dónde se abría la app.** El APK usa el servidor en la nube, pero
   `iniciar.ps1` compilaba la versión web contra un backend local con su propia base de datos
   SQLite. Una cuenta creada en el celular no existía en el PC, y al revés. Cada cambio obligaba a
   pensar contra qué servidor se estaba probando.
2. **La interfaz se parecía demasiado a UTB App.** ADR-0011 tomó de esa app los colores y también
   las formas (encabezado con arcos y esquinas redondeadas abajo, tarjetas grandes de acceso). El
   equipo quiere que solo se reconozcan los colores y que la forma sea propia.
3. **Poca información por pantalla.** Las tarjetas de acceso ocupaban un tercio de la pantalla, y
   la tarjeta destacada del inicio se veía como una caja cerrada dentro del encabezado.

## Decisión

1. **Un solo servidor para todos los clientes.** El APK, la web compilada por `iniciar.ps1` y
   cualquier compilación sin `--dart-define` usan el servidor en la nube
   (`ApiConfig.servidorProduccion`). El backend local queda para desarrollo con
   `iniciar.ps1 -Local`. La compilación web guarda en `build/web/servidor.txt` a qué servidor
   apunta y se recompila sola si cambia.
2. **Identidad propia sobre los colores de UTB App** (`frontend/lib/shared/utb_ui.dart`):
   - El motivo gráfico es el **plano de baldosas del logo**: una rejilla de salones que se apaga
     hacia la izquierda, con una baldosa encendida (el salón libre).
   - El encabezado **se desvanece hacia el fondo**, sin borde ni esquinas: ya no es un bloque.
   - La tarjeta destacada es de **vidrio** (deja ver el degradado), con un punto luminoso del
     color del estado y el número dentro de una baldosa.
   - Los accesos (Solicita un salón, Mis solicitudes, Inventario) son **filas compactas** de
     unos 64 px con ícono en baldosa, en lugar de tarjetas promocionales de unos 300 px.
   - La barra inferior tiene esquinas de baldosa (22 px) en vez de píldora, y la pestaña activa
     se enciende como una baldosa en degradado detrás del ícono.
3. **Escala global de 0,9** (`EscalaGlobal` en `frontend/lib/app.dart`): toda la app se dibuja
   un 10 % más pequeña, como bajar el "tamaño de pantalla" del teléfono, y caben más filas. Los
   toques, el teclado y los márgenes del sistema se ajustan solos.

## Alternativas consideradas

- **Sincronizar la base local con la nube:** complejo y propenso a conflictos. Un servidor único
  elimina el problema de raíz.
- **Bajar los tamaños de letra uno por uno:** decenas de cambios repartidos en todas las
  pantallas y fáciles de dejar incoherentes. La escala global es un solo punto de cambio.
- **`textScaler` del sistema:** solo achica el texto. Los espacios y los íconos seguían grandes.

## Consecuencias

- **Positivas:** las mismas cuentas y datos en el celular y en el PC; la app ya no se confunde
  con la de la Universidad; en el inicio caben unas 2 pantallas más de información.
- **Negativas:** probar en la web sin internet requiere `-Local`. Las funciones nuevas del
  backend solo llegan al celular cuando se despliegan en la nube (rama `main`). Con la escala
  global, los textos más pequeños quedan en unos 10 px: no conviene bajar más el factor.

## Trazabilidad

| Decisión | Código | Verificación |
|---|---|---|
| Servidor único | `frontend/lib/core/config/api_config.dart`, `iniciar.ps1` | `iniciar.ps1` comprueba `<servidor>/salud` antes de abrir el navegador |
| Identidad propia | `frontend/lib/shared/utb_ui.dart`, `frontend/lib/features/home/presentation/shell_page.dart`, `home_page.dart` | capturas de Inicio, Salones, Control y Perfil (estudiante y auxiliar) |
| Escala global | `frontend/lib/app.dart` (`EscalaGlobal`) | `flutter analyze`, `flutter test` y capturas |
| Documentación | `docs/identidad/identidad-visual.md`, `docs/COMO_EJECUTAR.md` | — |
