# Arquitectura de Seguridad y Privacidad — UTB Tracker

Este directorio contiene la documentación formal de seguridad, modelado de amenazas, auditoría de dependencias y privacidad de datos del sistema UTB Tracker para la entrega S13.

---

## 1. Resumen Ejecutivo (5 Líneas)

1. Se modeló el sistema UTB Tracker con metodología STRIDE sobre las fronteras de confianza del C4, priorizando 22 amenazas por riesgo técnico (P×I) con sus mitigaciones implementadas o propuestas. Las tres de mayor riesgo corresponden a T-01 (Auto-asignación de roles privilegiados, riesgo 25), T-02 (Clave secreta por defecto en JWT, riesgo 20) y T-03 (Enumeración de usuarios por IDs enteros, riesgo 20).
2. La vulnerabilidad más crítica detectada reside en la auto-asignación de roles privilegiados en el registro público (`POST /auth/register`), mitigable mediante la restricción del campo `rol` en el backend.
3. Se integró al pipeline de CI (`.github/workflows/ci.yml`) el paso de auditoría automatizada con `pip-audit`, el cual identificó vulnerabilidades conocidas en `Starlette` y `PyJWT`, documentando sus decisiones de actualización.
4. Se generó el inventario formal de dependencias de software (SBOM) en estándar CycloneDX v1.5 JSON, resguardado en `docs/seguridad/sbom/bom.json`.
5. Se construyó el inventario de datos personales tratados en las tablas del sistema bajo la Ley 1581 de 2012 de Colombia, formulando propuestas de minimización para perfiles, logs y almacenamiento local en Flutter.

---

## 2. Índice de Documentos

- [`modelo-amenazas.md`](modelo-amenazas.md): Modelado con las 4 preguntas, diagrama Mermaid de fronteras de confianza sobre C2, análisis STRIDE por componente, matriz de 22 amenazas priorizadas (P×I) con evidencia `archivo:línea`, responsables reales del equipo y amenazas aceptadas.
- [`analisis-dependencias.md`](analisis-dependencias.md): Integración de `pip-audit` en GitHub Actions, resultados reales de escaneo en backend y frontend (`flutter pub outdated`), catálogo de CVEs, especificación del SBOM, auditoría de secretos y análisis de despliegue sin Dockerfile.
- [`privacidad.md`](privacidad.md): Inventario de datos personales en modelos SQLAlchemy (`app/models/`), finalidades, bases jurídicas bajo Ley 1581 de 2012, análisis de minimización de datos y brechas de exposición.
- [`sbom/bom.json`](sbom/bom.json): Software Bill of Materials (SBOM) en formato estándar CycloneDX v1.5 JSON generado a partir de las dependencias del backend.
- [`../adr/0008-control-acceso-granular-recurso.md`](../adr/0008-control-acceso-granular-recurso.md): Decisión arquitectónica para mitigar vulnerabilidades BOLA/IDOR mediante control de autorización por recurso y propiedad de objetos.

---

## 3. Metodología de Verificación en el Repositorio

Toda afirmación técnica, código y tabla de este módulo fue validada directamente contra los archivos del repositorio:
- **Autenticación y Registro:** Verificado en `app/services/auth.py:40-44` y `app/schemas/auth.py:18` (auto-asignación de rol) y `app/routers/auth.py:53-59` (enumeración de perfiles).
- **Concurrencia y Consistencia:** Verificado en `app/services/prestamos_salon.py:114-138` (cruce de fechas en salones) y `app/services/loans.py:58` (bloqueo pesimista condicionado).
- **Almacenamiento Móvil:** Verificado en `frontend/lib/core/storage/token_storage.dart:18-19` (persistencia en `.utb_sesion.json`).
- **Escaneo de Vulnerabilidades:** Verificado ejecutando `pip-audit -r requirements.txt` y `flutter pub outdated` directamente en la terminal.
- **Trazabilidad en CI:** Verificado en `.github/workflows/ci.yml:51-55`.

---

## 4. Enlace al Commit

<PEGAR URL DEL COMMIT>
