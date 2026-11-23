# 0020 - Foto de perfil: miniatura limpia en una tabla aparte

## Estado

Aceptado (2026-11-16). Amplía ADR-0016 (perfil y preferencias en el servidor).

## Contexto

La persona quiere poner y cambiar su foto de perfil. Hay cuatro condiciones:

- Producción se despliega sola y no se puede editar su `.env`. Docker Compose no tiene
  volúmenes para archivos subidos.
- En el backend no estaban instalados `python-multipart` (subida de formularios) ni `Pillow`
  (imágenes). La regla del curso es no agregar paquetes sin justificarlos.
- Una foto del teléfono lleva metadatos EXIF, entre ellos la **ubicación GPS**.
- Un archivo subido puede ser malicioso: tener otra extensión, ser un archivo políglota (dos
  formatos a la vez), traer datos escondidos al final, venir truncado o ser enorme.

## Decisión

### 1. Dónde se guarda: tabla `fotos_perfil`

- **Contenido de la tabla:**
  - `usuario_id`: llave primaria y foránea, con `ON DELETE CASCADE`.
  - `contenido`: los bytes.
  - `tipo`, `tamano`, `ancho`, `alto`.
  - `version`: milisegundos de la última subida, siempre creciente.
  - `actualizado_en`.
- **Por qué no en disco:**
  - No hace falta ningún volumen nuevo y funciona igual en SQLite, PostgreSQL y Docker.
  - Los respaldos de la base incluyen las fotos.
  - Borrar la fila borra el contenido.
- **Por qué una tabla aparte:** las consultas de `usuarios` no cargan los bytes. `GET /auth/me`
  y `GET /usuarios` solo leen la versión.
- **Por qué los archivos en disco quedaron descartados:** necesitarían un volumen persistente en
  Docker y en el servidor de producción, más permisos de carpeta, y no se borrarían junto con la
  cuenta.

### 2. Endpoints

- `PUT /auth/me/foto`: sube o reemplaza la foto. El cuerpo son los bytes crudos, así que no
  hace falta `python-multipart`.
- `DELETE /auth/me/foto`: quita la foto.
- `GET /auth/me/foto`: devuelve la foto propia.
- `GET /usuarios/{id}/foto`: devuelve la foto propia, o la de otra persona a quien tenga el
  permiso `usuarios.ver` (auditor y administrador, para las listas). Un estudiante recibe 403
  por la foto de otra persona y sin sesión se recibe 401: **nunca es pública**.
- `GET /auth/me` y `GET /usuarios` agregan `tiene_foto` y `foto_version`. Son campos nuevos que
  no rompen nada.
- La app pide `?v=<versión>` y guarda en memoria la foto de cada versión, así que no la vuelve
  a descargar en cada pantalla.
- **Cabeceras de la respuesta:**
  - `Cache-Control: private` (ningún proxy la guarda).
  - `X-Content-Type-Options: nosniff`.
  - `Content-Security-Policy: default-src 'none'`.

### 3. Validación en el servidor, sin paquetes nuevos (`app/service/imagenes.py`)

- **Tamaño.** Máximo 200 KB (`FOTO_MAX_BYTES`). El cuerpo se lee en trozos y se corta apenas
  pasa el límite, aunque el cliente mienta en `Content-Length`. Responde 413.
- **Tipo.** Se decide por la **firma** del contenido (`FF D8 FF` para JPEG; `89 PNG` para
  PNG), nunca por la extensión ni por el `Content-Type`. Cualquier otra cosa responde 415.
- **Estructura.** Se recorre el archivo sin decodificarlo:
  - JPEG: sus segmentos. Debe tener tamaño (SOF), datos (SOS) y fin de imagen (EOI).
  - PNG: sus bloques, con el CRC verificado. Debe empezar con IHDR y terminar con IEND.
  - Si está truncado o dañado, responde 422.
- **Dimensiones.** Entre 32 y 512 px por lado (`FOTO_LADO_MAXIMO`). Si no, 422.
- **Se quitan los metadatos.**
  - JPEG: se eliminan APP1 a APP15 (EXIF con GPS, XMP, ICC) y los comentarios. Solo se conserva
    la **orientación**, en un EXIF mínimo nuevo de una sola etiqueta, para que la foto no salga
    girada.
  - PNG: solo se conservan IHDR, PLTE, IDAT, IEND, tRNS, gAMA, cHRM y sRGB. Se quitan, entre
    otros, tEXt, iTXt, zTXt y eXIf.
  - En los dos formatos se **descarta** todo lo que haya después del fin de la imagen (datos
    escondidos o archivos políglotas).
- **Frecuencia.** Máximo 10 subidas por hora por usuario (`FOTO_RATE_LIMIT`). Después, 429.
- **Por qué no se usa Pillow:** no se re-codifica la imagen en el servidor, porque haría falta
  Pillow. La app la reduce y la re-codifica **antes** de subirla, y el servidor verifica y
  limpia. Se comprobó con dos JPEG reales de las pruebas del motor de Flutter: después de
  limpiarlos se siguen decodificando, y el que tiene orientación se ve con la orientación
  correcta.

### 4. Privacidad y bitácora

- En la bitácora quedan `usuario.foto_actualizada` (con tipo, tamaño y dimensiones, nunca el
  contenido) y `usuario.foto_eliminada`.
- La foto se **borra** al quitarla, al desactivar la cuenta (por la persona o por un
  administrador) y, en cascada, si se borra el usuario.
- Más detalle en `docs/seguridad/privacidad.md`.

### 5. App

- Se agrega un paquete: `image_picker`, el oficial del equipo de Flutter, aprobado por el
  dueño.
- Abre la cámara o la galería y devuelve la foto ya reducida a 256 px y recomprimida (calidad
  82). `requestFullMetadata: false` evita pedir acceso a la ubicación de las fotos en iOS.
- **Hoja inferior:** "Tomar foto", "Elegir de la galería" y "Quitar foto", con vista previa
  antes de subir, estados de carga y errores. Si el sistema niega un permiso, la hoja explica
  dónde activarlo.
- La foto se ve en el perfil, en el encabezado de Inicio y en la lista de Usuarios. Si no hay
  foto, se mantienen las iniciales con el color elegido.
- **Permisos por plataforma:**
  - **Android:** no se declaran `CAMERA` ni permisos de almacenamiento. La cámara del sistema
    toma la foto y la galería usa el selector de fotos de Android; solo se agregó la consulta
    `IMAGE_CAPTURE` en el manifiesto.
  - **iOS:** el proyecto no tiene carpeta `ios/`. Si se agrega, `Info.plist` necesitará
    `NSCameraUsageDescription` y `NSPhotoLibraryUsageDescription`.
  - **Web:** el navegador pide el permiso por su cuenta.

## Consecuencias

- **Positivas:**
  - Sin paquetes nuevos en el backend ni volúmenes nuevos.
  - Las fotos guardadas no tienen la ubicación.
  - El tipo real lo decide el servidor.
- **Negativas:**
  - La base crece unos KB por persona con foto.
  - Si la app no reduce la foto (por ejemplo, un cliente distinto), el servidor rechaza las
    fotos grandes en vez de achicarlas.
- **APK instaladas:** las APK viejas ignoran los campos nuevos y siguen mostrando las iniciales.
  Para ver y subir fotos hay que instalar una APK nueva.

## Pruebas

- `tests/test_foto_perfil.py`:
  - JPEG y PNG válidos.
  - Archivos que no son imagen, aunque digan `.jpg`.
  - Demasiado grande, dañada, dimensiones fuera de rango.
  - Reemplazar y borrar.
  - `tiene_foto` y `foto_version`.
  - Permisos sobre la foto de otra persona.
  - Límite de frecuencia.
  - Borrado al desactivar.
  - Que el GPS no quede guardado.
- `frontend/test/perfil_foto_test.dart`: avatar con foto y sin foto, caché por versión y
  estados de la hoja (vista previa, error del servidor, formato no admitido, permiso negado,
  quitar).
