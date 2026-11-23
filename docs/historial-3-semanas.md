# UTB Tracker — Historial de las últimas 3 semanas

**Periodo:** 31 de octubre – 21 de noviembre de 2026
**Actividad:** 53 commits y 12 Pull Requests/merges, con trabajo de Mateo, Joriel Samir y Sebas.
**Estado actual:** todo lo descrito está unido a `main` y desplegado en la nube (`https://129-80-171-141.nip.io`).

---

## Resumen ejecutivo

En tres semanas el proyecto pasó de ser un gestor de préstamos genérico a una **aplicación de administración de salones de la UTB**: ocupación en vivo, solicitudes de salón, control del auditor, equipos fijos por salón, bitácora de auditoría, cuentas con correo institucional verificado, roles automáticos y un catálogo real de 57 salones cargado en producción.

| Área | Qué se logró |
|---|---|
| Producto | Enfoque en salones (los equipos ya **no se prestan**), catálogo UTB, habilitación y estado de equipos |
| Seguridad | Roles con una única matriz de permisos, correo verificado, dominio institucional, auditoría con exportación CSV |
| Calidad | SonarCloud con Quality Gate, 26 hallazgos resueltos, pruebas en PostgreSQL, control de erosión de capas |
| Operación | CI/CD que despliega al unir a `main`, Docker Compose, notificaciones push (Firebase) |
| Diseño | Identidad visual propia (logo pin de salones, paleta UTB App), escala de texto, app Flutter por permisos |
| Documentación | ADR-0009 a ADR-0023, arc42, modelo de amenazas, trazabilidad con IA (`docs/ia.md`) |

---

## Semana 1 (31 oct – 6 nov): Base técnica, notificaciones y CI

*Responsable principal: Joriel Samir*

- **Endurecimiento del backend:** plan de acción completo de robustez (`b0fa431`).
- **Notificaciones push:** integración de Firebase en la app (`d8f840a`) y envío de push desde la mensajería con cuerpo del mensaje (`a8646c8`).
- **Integración continua:** reintentos en la verificación de salud del despliegue, pruebas de concurrencia en PostgreSQL y ajustes al escaneo de vulnerabilidades (`edbf314`, `c0ac459`, `9c42fe7`).
- **Calidad:** corrección de hallazgos de SonarCloud en worker y backend (`d844ad6`).
- **Documentación de arquitectura:** explicación del diseño y de los patrones usados (`d4dc2ca`, `38bacb3`, `4948e52`).
- 4 PRs unidos a `main` (#5, #6, #7, #8).

## Semana 2 (7 – 14 nov): Rediseño, identidad propia y auditoría

*Responsable principal: Mateo, con aportes de Sebas*

- **Cambio de enfoque (ADR-0009/0010):** la app se centra en administrar **salones**; los equipos son fijos por salón y no se prestan. Se retiró el préstamo de equipos de la app.
- **Auditoría:** registro de cambios con exportación a CSV (`a716b6a`) y pestaña Control.
- **Nuevo diseño:** paleta estilo UTB App, salones del usuario con encabezado en degradado y filtro por edificio, control de salón con tarjeta, nombres reales e inventario por salón.
- **Identidad propia (ADR-0011):** logo pin de salones, ícono adaptativo, splash y login en degradado, escala de texto 0,9 → 1,10, versión web contra la nube.
- **Despliegue:** Docker Compose con base de datos, API, worker, web y datos de ejemplo (`6b56c2d`).
- **Cuentas y perfil:** correo verificado, perfil completo, tipo y equipamiento de salones (`6216f08`), PR #14.
- **Calidad:** 26 hallazgos de SonarCloud resueltos (`b3d56fc`).
- **Aporte de Sebas:** medición empírica de atributos de calidad (`9b7d2bb`) y documentación de URLs de despliegue (`bc476cf`).

## Semana 3 (15 – 21 nov): Roles, catálogo UTB y producción

*Responsable principal: Mateo, con aportes de Sebas en CI*

- **Roles y permisos (ADR-0018, PR #15):** una única tabla rol → permisos en el backend y su espejo en la app. Estudiante, Auditor y Administrador. Todo endpoint nuevo exige una fila en la matriz de permisos y lo verifica una prueba automática.
- **Correo institucional (PR #16 y #17, ADR-0019):** registro solo con el dominio UTB y **rol automático** según la lista de asignaciones; foto de perfil con limpieza de metadatos EXIF (ADR-0020).
- **Catálogo de salones (PR #18):**
  - Fase 4: catálogo UTB con regla del código (por ejemplo A1-101) y carga desde archivo (ADR-0021).
  - Fase 5: habilitación del salón separada de la ocupación y equipos fijos con estado (ADR-0022).
  - Fase 6: revisión, datos de ejemplo completos y apertura limpia de la app.
- **Organización según el curso (ADR-0023):** documentación S04 y S09, **control de erosión de capas** con prueba automática (`tests/test_erosion_capas.py`), retiro del estado "prestado" y marcado de los endpoints antiguos como obsoletos.
- **CI y SonarCloud (Sebas):** Quality Gate restaurado, fijación del commit SHA y ajuste de pruebas de rutas.
- **Catálogo en la nube (PR #19):** una migración carga automáticamente los **57 salones UTB** al desplegar, de modo que los estudiantes ya ven la lista en la app. Verificada en PostgreSQL y repetible sin duplicar datos.
- **Cuentas de prueba:** una por rol en producción para validar la app.

## Herramientas de trabajo con IA (21 nov)

- Grafo de conocimiento del proyecto reconstruido: 4.936 nodos y 218 comunidades, para ubicar código y documentos con menos lectura.
- Servidor Headroom: se subió el tiempo de espera de MCP a 120 s para que conecte de forma estable.

---

## Pendientes

- **Correo real:** sin `USE_REAL_MAIL=true` las cuentas nuevas nacen verificadas (ADR-0014). Falta configurar el worker de correo.
- **Cuenta de administrador:** crearla en el servidor con `scripts/crear_admin.py`, que requiere acceso al servidor.
- **APK:** publicarla en GitHub Releases. La copia actual está en el escritorio y no se actualiza sola.
- **Roles reales:** cargar la lista oficial con `scripts/cargar_asignaciones.py`.

## Cifras del periodo

| Métrica | Valor |
|---|---|
| Commits (sin merges) | 53 |
| Pull Requests unidos | 12 |
| ADR nuevos | 0009 al 0023 |
| Salones en producción | 57 |
| Aportes por persona | Mateo 32 · Joriel Samir 12 · Sebas 6 (aprox.) |
