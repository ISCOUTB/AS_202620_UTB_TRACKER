# 0026 - La app usa el logo de la UTB

## Estado

Aceptado (2026-11-23). **Reemplaza** el logo propio (pin con plano de salones) que fijó
ADR-0013, que modificaba el punto 4 de ADR-0011. La paleta no cambia.

## Contexto

- ADR-0013 había elegido un símbolo propio para no parecerse a UTB App. Para la entrega final el
  dueño pidió que la app lleve el **logo de la UTB** (letras U, T y B en bloque, azules sobre
  blanco), igual al ícono de UTB App que se ve en el celular.
- La app es un proyecto académico de la UTB, hecho para su campus.

## Decisión

1. El logo es el de la UTB: polígono azul `#0939D7` sobre baldosa blanca. Se redibujó como
   vector con medidas tomadas de una captura del ícono oficial (no se copió ningún archivo de la
   Universidad), así que escala sin pérdida.
2. Se usa en: ícono del lanzador de Android (clásico y adaptable, fondo blanco), pantalla nativa
   de arranque (Android 12+ y anteriores), pantalla de arranque de Flutter, favicon y íconos de
   la versión web, pantalla de inicio de sesión y encabezado de Inicio.
3. Fuente única de los archivos: `frontend/assets/icono/*` y `frontend/assets/figuras/logo.svg`
   (copia en `docs/identidad/`). Se regeneran con `dart run flutter_launcher_icons` y
   `dart run flutter_native_splash:create`.
4. Lo demás de ADR-0011/0013 sigue igual (colores, interfaz compacta, servidor único). El texto de
   la marca sigue siendo "UTB Tracker · Campus Tecnológico".

## Consecuencias

- La app se reconoce como de la UTB de un vistazo.
- El logo pertenece a la Universidad: se usa con fines académicos. Si el proyecto saliera del
  curso habría que pedir autorización a Mercadeo/Comunicaciones de la UTB.
- El APK de versiones anteriores sigue mostrando el pin; hay que instalar la v1.1.0.
