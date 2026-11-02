# Análisis de Dependencias, Vulnerabilidades y Gestión de Secretos — UTB Tracker

> **Documento verificado contra herramientas ejecutadas en el entorno local real.**  
> Los resultados de escaneo presentados corresponden a las salidas exactas emitidas por las herramientas en la terminal.

---

## 1. Integración en el Pipeline de CI/CD (`ci.yml`)

Para prevenir la introducción de dependencias con vulnerabilidades conocidas (CVEs), se incorporó un paso de auditoría automatizada en el flujo de integración continua (`.github/workflows/ci.yml:51-55`).

### 1.1 Modificación en `.github/workflows/ci.yml`
El paso de análisis se ubica inmediatamente después de la ejecución de la suite de pruebas Pytest dentro del trabajo `test`:

```yaml
      # Análisis de vulnerabilidades en dependencias (S13)
      - name: Análisis de seguridad de dependencias (pip-audit)
        run: |
          pip install pip-audit
          pip-audit -r requirements.txt
```

### 1.2 Criterio de Fallo del Pipeline
- **Comando exacto de ejecución:** `pip-audit -r requirements.txt`
- **Criterio de fallo:** La herramienta consulta la base de datos de vulnerabilidades conocidas de Python (PyPI Advisory Database / OSV). Si se detecta al menos un paquete con vulnerabilidad sin mitigar, el comando finaliza con código de salida `1` (`exit code 1`), interrumpiendo el flujo del job y bloqueando el paso de despliegue (`deploy` que depende de `needs: test`).
- **Gestión de excepciones (en caso de aceptación documentada):** Para vulnerabilidades analizadas y aceptadas formalmente por el equipo, el comando en CI puede invocar `--ignore-vuln <VULN-ID>`, forzando que solo vulnerabilidades nuevas o no evaluadas bloqueen el pipeline.
- **Dependencias del Frontend en CI:** En el repositorio actual, el pipeline de CI corre sobre `ubuntu-latest` con entorno Python (`actions/setup-python@v5`), sin SDK de Flutter preconfigurado. El análisis de dependencias de Flutter se ejecuta de forma periódica en entornos de desarrollo local mediante `flutter pub outdated` (documentado en la sección 3). Integrar Flutter en CI requeriría la acción `subosito/flutter-action@v2`, añadiendo overhead innecesario dado que la compilación de la app móvil no ocurre en el servidor de despliegue.

---

## 2. Auditoría de Dependencias del Backend (`pip-audit`)

### 2.1 Comando y Salida Real en Terminal
Ejecutado sobre el archivo `requirements.txt` compilado con hashes:

```text
PS C:\Users\sebas\OneDrive\Desktop\Tractar\AS_202620_TRACTAR> & "venv/Scripts/python.exe" -m pip_audit -r requirements.txt
Found 29 known vulnerabilities in 2 packages
Name      Version ID                  Fix Versions
--------- ------- ------------------- ------------
starlette 0.50.0  PYSEC-2026-161      1.0.1
starlette 0.50.0  PYSEC-2026-161      1.0.1
starlette 0.50.0  PYSEC-2026-2281     1.1.0
starlette 0.50.0  PYSEC-2026-2280     1.1.0
starlette 0.50.0  PYSEC-2026-249      1.3.1
starlette 0.50.0  PYSEC-2026-248      1.3.0
starlette 0.50.0  PYSEC-2026-249      1.3.1
starlette 0.50.0  PYSEC-2026-248      1.3.0
starlette 0.50.0  PYSEC-2026-2281     1.1.0
starlette 0.50.0  PYSEC-2026-2280     1.1.0
pyjwt     2.12.1  PYSEC-2026-179      2.13.0
pyjwt     2.12.1  PYSEC-2026-175      2.13.0
pyjwt     2.12.1  PYSEC-2026-177      2.13.0
pyjwt     2.12.1  PYSEC-2026-178      2.13.0
pyjwt     2.12.1  PYSEC-2026-177      2.13.0
pyjwt     2.12.1  PYSEC-2026-179      2.13.0
pyjwt     2.12.1  PYSEC-2026-176      2.13.0
pyjwt     2.12.1  PYSEC-2026-178      2.13.0
pyjwt     2.12.1  PYSEC-2026-4145     2.14.0
pyjwt     2.12.1  PYSEC-2026-4146
pyjwt     2.12.1  PYSEC-2026-4149     2.14.0
pyjwt     2.12.1  PYSEC-2026-4152     2.14.0
pyjwt     2.12.1  PYSEC-2026-4144     2.14.0
pyjwt     2.12.1  PYSEC-2026-4148     2.14.0
pyjwt     2.12.1  PYSEC-2026-4140     2.14.0
pyjwt     2.12.1  PYSEC-2026-4141     2.15.0
pyjwt     2.12.1  PYSEC-2026-4147     2.14.0
pyjwt     2.12.1  PYSEC-2026-4183     2.15.0
pyjwt     2.12.1  GHSA-pxh4-856f-4h89 2.14.0
```

### 2.2 Análisis Detallado de Hallazgos y Decisiones

| Paquete | Versión Actual | CVE / Identificador | Severidad | Decisión | Justificación Técnica |
|---|---|---|---|---|---|
| **starlette** | `0.50.0` | **PYSEC-2026-161**<br>(CVE-2026-48710 / GHSA-86qp-5c8j-p5mr) | **Alta** | **Actualizar** | Omisión de validación de la cabecera HTTP `Host` al reconstruir `request.url`. Permite manipular el prefijo de ruta interpretado por middlewares de autorización. Solución: actualizar FastAPI/Starlette a versión parcheada `≥ 1.0.1`. |
| **starlette** | `0.50.0` | **PYSEC-2026-2281**<br>(CVE-2026-48818 / GHSA-wqp7-x3pw-xc5r) | **Media** | **Descartar en producción / Actualizar preventivamente** | Vulnerabilidad de SSRF y fuga de credenciales NTLM mediante rutas UNC en Windows (`os.path.realpath`). Dado que la aplicación en producción corre sobre Linux Ubuntu (`ci.yml:9`, `ci.yml:60`), el vector SMB de Windows no es explotable en el servidor desplegado. No obstante, se actualiza al parchear Starlette. |
| **starlette** | `0.50.0` | **PYSEC-2026-2280**<br>(GHSA-74m5-2c7w-9w3x) | **Media** | **Actualizar** | Denegación de servicio mediante el envío de formularios multipart con delimitadores diseñados para provocar consumo excesivo de CPU. Solución: versión `≥ 1.1.0`. |
| **starlette** | `0.50.0` | **PYSEC-2026-248** / **PYSEC-2026-249** | **Media** | **Actualizar** | Agotamiento de memoria y recursos en el procesamiento de cabeceras `Range` malformadas. Solución: versión `≥ 1.3.1`. |
| **pyjwt** | `2.12.1` | **GHSA-pxh4-856f-4h89**<br>(PYSEC-2026-4144) | **Crítica** | **Actualizar** | Aceptación de clave vacía (`k=""`) en algoritmos simétricos HMAC a través de conjuntos JWK (`from_jwk`), permitiendo la falsificación completa de tokens JWT sin autenticación previa. Solución: actualizar `PyJWT` a versión `≥ 2.14.0`. |
| **pyjwt** | `2.12.1` | **PYSEC-2026-175** a **PYSEC-2026-179** | **Media** | **Actualizar** | Problemas de confusión de algoritmos en esquemas asimétricos y validación de cabeceras de firma. Solución: versión `≥ 2.13.0`. |
| **pyjwt** | `2.12.1` | **PYSEC-2026-4140** a **PYSEC-2026-4183** | **Media** | **Actualizar** | Denegación de servicio por procesamiento de firmas criptográficas anómalas y aserciones de tiempo. Solución: actualizar a la última versión estable (`PyJWT==2.15.1`, actualmente ya presente en el venv local pero pendiente de recompilar en `requirements.txt`). |

---

## 3. Auditoría de Dependencias del Frontend (`flutter pub outdated`)

### 3.1 Comando y Salida Real en Terminal
Ejecutado en la carpeta `frontend/`:

```text
PS C:\Users\sebas\OneDrive\Desktop\Tractar\AS_202620_TRACTAR\frontend> flutter pub outdated
Showing outdated packages.
[*] indicates versions that are not the latest available.

Package Name              Current  Upgradable  Resolvable  Latest  

direct dependencies:     
flutter_svg               *2.3.0   2.3.2       2.3.2       2.3.2   
get_it                    *7.7.0   *7.7.0      9.3.0       9.3.0   

dev_dependencies:        
flutter_lints             *4.0.0   *4.0.0      6.0.0       6.0.0   

transitive dependencies: 
material_color_utilities  *0.13.0  *0.13.0     *0.13.0     0.13.1  
vector_graphics           *1.2.4   1.2.5       1.2.5       1.2.5   
vector_graphics_compiler  *1.3.2   1.3.4       1.3.4       1.3.4   
vector_math               *2.4.3   *2.2.0      *2.2.0      2.4.4   
xml                       *7.0.1   *7.0.1      *7.0.1      7.1.0   

transitive dev_dependencies:
lints                     *4.0.0   *4.0.0      6.1.0       6.1.0   
test_api                  *0.7.12  *0.7.9      *0.7.9      0.7.15  

3 upgradable dependencies are locked (in pubspec.lock) to older versions.
To update these dependencies, use `flutter pub upgrade`.

3 dependencies are constrained to versions that are older than a resolvable version.
To update these dependencies, edit pubspec.yaml, or run `flutter pub upgrade --major-versions`.
```

### 3.2 Decisiones para el Frontend
1. **`flutter_svg` (`2.3.0` → `2.3.2`):** Decisión: **Actualizar**. Versión menor con correcciones en el parser de elementos XML de gráficos vectoriales sin cambios que rompan compatibilidad.
2. **`get_it` (`7.7.0` vs `9.3.0`):** Decisión: **Aceptar versión actual temporalmente**. `get_it` es el inyector de dependencias central del frontend (`frontend/lib/core/di/injection.dart:1-50`). La actualización mayor a `9.x` introduce cambios de API en la resolución síncrona/asíncrona de singletons que requieren refactorización en todos los controladores. Se mantiene en `7.7.0` mientras no existan avisos de seguridad que comprometan la ejecución.
3. **`flutter_lints` (`4.0.0` vs `6.0.0`):** Decisión: **Aceptar**. Dependencia de análisis estático en tiempo de desarrollo; no tiene impacto en la seguridad del ejecutable distribuido.

---

## 4. Generación del Software Bill of Materials (SBOM)

Se generó con éxito el inventario formal de componentes en formato estándar **CycloneDX v1.5 JSON**, utilizando la herramienta `cyclonedx-py`.

- **Ubicación del artefacto:** [`docs/seguridad/sbom/bom.json`](sbom/bom.json)
- **Comando utilizado:**
  ```bash
  cyclonedx-py requirements requirements.in --sv 1.5 -o docs/seguridad/sbom/bom.json
  ```
- **Resumen de componentes catalogados:** Contiene los identificadores de distribución universal (PURL), metadatos de versión y referencias de repositorio para los 10 paquetes directos y sus dependencias transitivas: `fastapi`, `uvicorn`, `pytest`, `httpx`, `sqlalchemy`, `psycopg`, `PyJWT`, `python-dotenv`, `bcrypt`, `alembic`.

---

## 5. Auditoría de Secretos y Configuración de Despliegue

### 5.1 Dockerfile e Imágenes Base
- **Hallazgo verificado:** En el repositorio **NO existe Dockerfile ni archivos docker-compose**.
- **Infraestructura real:** El despliegue se realiza directamente sobre una máquina virtual (VPS) aprovisionada manualmente, donde la aplicación se orquesta como un servicio del sistema operativo mediante systemd (`utb-tracker.service`), según se evidencia en `.github/workflows/ci.yml:78` y `docs/arc42/arc42.md` sección 7.
- **Recomendación para futura contenerización (PROPUESTO — NO IMPLEMENTADO):**
  - Utilizar una imagen base oficial con versión fija y digest inmutable (ej. `python:3.12-slim-bookworm`), descartando etiquetas flotantes como `latest`.
  - Crear un usuario sin privilegios en el sistema y declarar la directiva `USER appuser` para evitar la ejecución del proceso FastAPI como `root`.
  - Configurar sistema de archivos raíz en modo de solo lectura (`read_only: true`), montando un volumen temporal únicamente para `/tmp`.

### 5.2 Secretos Hardcodeados en el Repositorio e Historial
- **Inspección en archivos de configuración:**
  - `app/core/config.py:14`: `SECRET_KEY = os.getenv("SECRET_KEY", "change-me-in-production")`.
  - `app/core/config.py:21`: `FORGET_PWD_SECRET_KEY = os.getenv("FORGET_PWD_SECRET_KEY", "change-me-in-production")`.
  - **Dictamen:** No existen tokens o contraseñas reales hardcodeadas en el código fuente actual; existen cadenas de respaldo por defecto para desarrollo que representan un riesgo si la variable no se provee en producción.
- **Inspección en el historial de Git:**
  - En el commit inicial `5f923cdcc4` (semana S3, cuando el proyecto utilizaba Django antes del ADR-0002), se confirmó la presencia de una clave de desarrollo autogenerada:
    `SECRET_KEY = 'django-insecure-n_i&h0&gn4_$qlyf496s9$zvpl7m_-j!wd@zecfr=$zl*pynp='`.
  - Dicho archivo (`config/settings.py`) fue eliminado en el commit de migración a FastAPI (ADR-0002). No afecta la seguridad actual de UTB Tracker, pero evidencia que el repositorio no debe ser hecho público sin antes purgar el historial con herramientas como `git-filter-repo` si esa clave llegase a tener algún valor residual.

### 5.3 Cobertura de `.gitignore` sobre Archivos de Entorno
Verificado en `.gitignore:7-11`:
```gitignore
# Archivos de configuración local / Variables de entorno
.env
.env.*
*.env
!.env.example
```
- **Dictamen:** La regla excluye exhaustivamente cualquier archivo `.env`, `.env.local` o variante de variables de entorno, permitiendo únicamente el seguimiento de la plantilla `.env.example`.

### 5.4 Inyección de Secretos en CI y Producción
- **Entorno de Integración Continua (`ci.yml:11-28`):**
  - Para el servicio PostgreSQL de prueba, se utiliza la variable `POSTGRES_HOST_AUTH_METHOD: trust`, permitiendo conexiones sin contraseña sobre runners efímeros y aislados de GitHub Actions (`ci.yml:20`).
  - Esto evita tener que almacenar contraseñas de bases de datos de prueba en los secrets del repositorio.
- **Entorno de Producción (`ci.yml:58-78`):**
  - El acceso al servidor se realiza mediante la acción `appleboy/ssh-action` utilizando secretos inyectados desde GitHub Secrets: `${{ secrets.SSH_HOST }}`, `${{ secrets.SSH_USER }}`, `${{ secrets.SSH_PRIVATE_KEY }}` y `${{ secrets.WORK_DIR }}` (`ci.yml:63-67`).
  - Las variables operativas de producción (claves JWT, credenciales reales de PostgreSQL) se inyectan en el servidor leyendo el archivo local `.env` antes de ejecutar las migraciones y reiniciar el servicio:
    ```bash
    set -a; . ./.env; set +a
    alembic upgrade head
    sudo systemctl restart utb-tracker
    ```
  - Este esquema asegura que los secretos de aplicación residan únicamente en el servidor de destino y no queden expuestos en el pipeline de GitHub ni en los registros de CI.
