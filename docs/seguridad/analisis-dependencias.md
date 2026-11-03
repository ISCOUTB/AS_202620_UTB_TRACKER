# Análisis de dependencias y gestión de secretos

## Alcance

El backend se instala desde `requirements.txt`, un lock generado con
`pip-compile --generate-hashes` a partir de `requirements.in`. CI usa Python
3.12 y PostgreSQL 16, y ejecuta la misma instalación reproducible que se
espera en producción.

## Auditoría en CI

El workflow [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) ejecuta:

```bash
pip-audit -r requirements.txt --require-hashes
```

El paso es bloqueante: no usa `continue-on-error` ni una lista de exclusiones.
Si el auditor encuentra una vulnerabilidad sin corregir, el job de pruebas
falla y el despliegue no comienza. Las actualizaciones se deben hacer primero
en `requirements.in`, regenerar el lock y ejecutar la suite completa.

Dependencias sensibles revisadas en esta remediación:

- `starlette==1.3.1`, fijado explícitamente junto con FastAPI.
- `PyJWT==2.15.1`, para corregir los hallazgos de la versión anterior.

La salida de `pip-audit` debe conservarse como evidencia del run de CI. No se
deben presentar exclusiones como si fueran correcciones. Si una excepción
temporal fuera inevitable, debe registrar identificador, riesgo, responsable,
mitigación y fecha de vencimiento en un cambio revisable.

## Pruebas y base de datos

Las pruebas priorizan `TEST_DATABASE_URL`. Cuando no está definida, usan una
SQLite temporal aislada únicamente como alternativa local. Nunca hacen
fallback a `DATABASE_URL` para luego ejecutar `drop_all`, porque esa variable
puede apuntar a una base compartida o de producción.

Producción rechaza SQLite y rechaza las claves JWT predeterminadas. Las claves
`SECRET_KEY` y `FORGET_PWD_SECRET_KEY` deben ser aleatorias, distintas y
proporcionadas mediante el entorno.

## Secretos y correo

Las credenciales SMTP, SSH, JWT y Firebase se configuran mediante secretos del
entorno o del proveedor de CI. No deben escribirse en el repositorio ni en
logs. El correo real solo se activa con `USE_REAL_MAIL=1` y configuración SMTP
completa; el notificador local no acredita entrega externa.

## Verificación de despliegue

Después de migrar y reiniciar el servicio, el deploy exige:

```bash
curl --fail --silent --show-error --max-time 15 \
  https://129-80-171-141.nip.io/salud
```

Este health check ejecuta `SELECT 1` contra PostgreSQL. Para acreditar el
recorrido completo aún deben ejecutarse pruebas de aceptación contra el
entorno servido: autenticación, préstamo, autocancelación, expiración y
mantenimiento. La publicación del APK por sí sola no sustituye esas pruebas.
