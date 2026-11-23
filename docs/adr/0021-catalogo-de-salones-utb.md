# 0021 - Catálogo de salones de la UTB: regla del código y carga desde un archivo de datos

## Estado

Aceptado (2026-11-16). Amplía ADR-0017 (tipo de salón) y ADR-0018 (roles y permisos).

> **Nota (2026-11-21):** los datos de demostración (equipos, horarios, solicitudes, reportes y bitácora) se agregan SOBRE los salones de este catálogo con `scripts/cargar_equipos_demo.py` y `scripts/cargar_demo_actividad.py`: nunca crean salones y todo lo ficticio queda marcado (`DEMO-` en los seriales, semestre `2026-2 DEMO`, estudiantes `estNN.demo@`). Reglas del dueño: A1-402 a A1-407 salas de computadores, A5 laboratorios de química.

## Contexto

- La app necesita los salones reales del Campus Tecnológico (Ternera). Hasta ahora solo había
  salones de ejemplo, creados a mano.
- **No se encontró un listado oficial completo.** Se buscó en utb.edu.co,
  repositorio.utb.edu.co y biblioteca.utb.edu.co. Resultados:
  - El repositorio institucional usa nombres como "Salón A2-501", pero sin una lista.
  - Una tesis de la biblioteca de la UTB
    ([Ramírez León, 2007](https://biblioteca.utb.edu.co/notas/tesis/0043111.pdf), tabla 48)
    nombra los locales **A1 402 a A1 407**. Dice que son las salas de informática del piso 4
    del edificio de Aulas 1. También cuenta que el salón **A2-201** queda sobre los
    laboratorios del piso 1 de Aulas 2.
  - El repositorio (repositorio.utb.edu.co) bloquea las descargas automáticas con una prueba
    anti-bots, así que sus PDF no se pudieron revisar.
- El equipo dio una lista provisional. La tesis la **contradice** en un punto: la lista decía
  que el piso 4 de A1 tenía 401–405, pero la tesis nombra 406 y 407.
- El rol que administra salones (Auditor) podía crear salones. Eso permite errores en el
  catálogo, por ejemplo "A1-1011" o un edificio que no coincide con el código.

## Decisión

### 1. Regla del código, en UN solo lugar

- **Formato:** `A` + edificio (1 dígito) + `-` + piso (1 dígito) + salón (2 dígitos).
  - A1-101 = edificio A1, piso 1, salón 01.
  - A2-505 = edificio A2, piso 5, salón 05.
- **Dónde vive la regla:** en `app/services/catalogo.py`. Su espejo para avisar antes de
  enviar está en `frontend/lib/features/salones_admin/domain/catalogo.dart`.
- **Normalización:** el código se guarda en mayúsculas y sin espacios.
- **Coincidencia:** el `edificio` ("A2") y el `piso` (5) guardados deben coincidir con los
  dígitos del código. Si no coinciden, la respuesta es 422 con un mensaje en español.
  - Si faltan, se completan solos.
  - La `ubicacion` legible ("Edificio A2, piso 5") también se completa sola.
- **Espacios especiales:** la regla solo se aplica a los nombres que empiezan por "A" + un
  dígito. Los demás se aceptan sin la regla, por ejemplo "Auditorio Napoleón de la Rosa" o
  "ALC-201". Así:
  - no se rompen los salones reales creados a mano en producción;
  - se pueden registrar espacios que no son aulas.
- **Orden natural:** como el formato tiene ancho fijo, el orden alfabético del nombre ya es el
  natural (A1-101, A1-102 … A1-201 … A2-201). Por eso se ordena en la base de datos, sin
  cargar todo en memoria.

### 2. Catálogo en un archivo de DATOS, corregible sin tocar código

- **Archivo:** `scripts/datos/catalogo_utb.json`. Trae los rangos por edificio y piso, la
  fuente de cada uno, los supuestos y los tipos que marca una fuente.
- **Estado: PROVISIONAL, pendiente de confirmar con Planta Física o Registro Académico.**
  El archivo y la guía lo dicen.
- **Total: 59 salones.** Son los 57 de la lista del equipo, más A1-406 y A1-407 que aporta la
  tesis.
  - A1-401 queda porque está en la lista del equipo, aunque la tesis no lo menciona.
  - Supuestos que hay que confirmar:
    - los pisos 3 y 4 de A1 son "igual" al piso 2;
    - A5 solo tiene el piso 2.
- **Tipos:** A1-402 a A1-407 quedan como `laboratorio_computo`, porque la fuente los describe
  como salas de informática. Hay que confirmarlo: la fuente es de 2007. Los demás quedan como
  `aula`: no se inventan laboratorios.
- **Capacidad:** no hay un dato oficial. Todos nacen con 40 y con `capacidad_estimada = true`
  (columna nueva). La app los marca como "estimado". El valor pasa a `false` cuando alguien
  edita la capacidad.
- **No incluidos:** el piso 1 de A2. La tesis describe allí laboratorios y oficinas, pero los
  códigos A2-101 a A2-107 solo aparecen en las placas de los aires acondicionados. Queda
  anotado en el archivo, en `no_incluidos`, para decidirlo.

### 3. Carga idempotente que nunca borra

- **Script:** `scripts/cargar_catalogo_utb.py`, con modo `--simular`.
  - Crea los salones que falten y no toca los existentes.
  - Informa cuántos creó y cuántos omitió.
  - Muestra el reporte de **salones fuera del catálogo**.
- **El reporte** (`GET /salones/catalogo/fuera`) es de solo lectura. Para cada salón trae una
  propuesta, y la decisión es del administrador. Hay tres casos:
  - el nombre no tiene la forma A1-101;
  - el edificio o el piso no coinciden con el código;
  - el código está bien formado, pero no está en el catálogo.
  El reporte también dice si el salón tiene historial: en ese caso, no se debe borrar.
- **Nunca corre solo:** ni en las migraciones ni al arrancar el servidor.

### 4. Permisos: solo el Administrador maneja el catálogo

- **Permiso nuevo:** `salones.crear_catalogo`, solo para el Administrador. Lo exigen:
  - `POST /salones`;
  - `DELETE /salones/{id}` (desactiva el salón: nunca lo borra);
  - `POST /salones/catalogo/rango/vista-previa` y `POST /salones/catalogo/rango` (crear
    varios);
  - `GET /salones/catalogo/fuera`.
- **Renombrar o mover:** `PUT /salones/{id}` sigue abierto al Auditor para lo demás (tipo,
  descripción, capacidad). Si el cambio toca `nombre`, `edificio` o `piso`, el servicio
  responde 403 a quien no tenga el permiso.
- **Efecto en APK viejas:** un Auditor con una APK vieja ya no puede crear salones (recibe
  403). Es intencional y no rompe nada más.
- **Crear varios:** se hace con **vista previa obligatoria** en la app. Se audita una sola
  entrada `salon.crear_lote` con la lista de creados y omitidos.

### 5. Listado completo

- `GET /salones` ahora devuelve hasta 100 salones si no se pide otro límite (antes eran 50).
  Así una APK vieja ve los 59 salones del catálogo.
- La app nueva pide todas las páginas.
- **Filtro nuevo `piso`.** Se agrega a los filtros que ya había de edificio, tipo y equipo. La
  app usa los mismos chips de edificio y piso en el catálogo, en el panel del Auditor y en la
  pantalla del Estudiante.

## Consecuencias

- **Positivas:**
  - Los códigos del catálogo no pueden quedar mal formados.
  - La lista se corrige editando un JSON.
  - Lo que falta confirmar queda escrito y es visible en la app ("estimado", "pendiente de
    confirmar").
- **Negativas:**
  - Mientras Planta Física no confirme, el catálogo puede tener salones que no existen o
    faltarle algunos. El reporte de reconciliación y la desactivación lo mitigan.
  - Un Auditor con una APK vieja ve fallar "crear salón".
- **Compatibilidad:**
  - Todo es aditivo: la columna `capacidad_estimada` tiene `server_default false` y el campo
    sale en la respuesta.
  - No cambian los valores guardados de `estado`.
  - Una sola migración nueva: `c9d0e1f2a3b4`.
