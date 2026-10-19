# ADR-0004: Seguridad y Autenticación — JWT Autofirmado

## Estado

Aceptado

## Contexto

El sistema distingue dos roles con permisos distintos: **auxiliar de planta**
(administrador del catálogo) y **usuario UTB** (estudiante/profesor que solo consulta y
solicita préstamos). Sin un mecanismo de autenticación, cualquier cliente podría alterar
el catálogo o el estado de recursos que no le corresponden, violando el escenario de
calidad QS-04 (Seguridad) y la Ley 1581 de 2012 (restricción legal, arc42 sección 2.3).

Se debe elegir el mecanismo de autenticación y autorización del API REST.

Esta decisión corresponde al aspecto **A-05 (Control de acceso por rol)** en
`docs/aspectos.md`.

## Decisión

Se utiliza **JSON Web Tokens (JWT) autofirmados** con el algoritmo **HS256**
implementados mediante la librería `PyJWT`. El flujo es:

1. El cliente envía credenciales (`nombre` + `password`) a `POST /auth/login`.
2. El backend valida las credenciales, genera un JWT firmado con una clave secreta
   (almacenada en variable de entorno `SECRET_KEY`) y lo devuelve.
3. El cliente incluye el token en la cabecera `Authorization: Bearer <token>` en cada
   petición protegida.
4. Una dependencia de FastAPI (`Depends(get_current_user)`) decodifica y verifica la
   firma del token en cada router que lo requiera, sin consultar la base de datos en
   cada petición.

Las contraseñas se almacenan con **hashing irreversible** usando `bcrypt`
(librería `passlib`), nunca en texto plano.

## Alternativas evaluadas

**Sesiones con cookies / base de datos de sesiones.**
- *Descartada:* requeriría almacenamiento de estado del lado del servidor (tabla de
  sesiones), complicando el escalado horizontal y añadiendo una consulta de BD por
  request solo para autenticar. Los JWT permiten verificación local sin estado adicional,
  lo cual encaja mejor con el backend stateless de FastAPI.

**OAuth2 con proveedor externo (Google, Microsoft).**
- *Descartada:* el sistema es interno a la UTB y los usuarios son auxiliares, profesores
  y estudiantes con cuentas propias del sistema. Delegar autenticación a un proveedor
  externo introduce una dependencia de red adicional y complejidad fuera del alcance del
  semestre.

**API Keys estáticas por cliente.**
- *Descartada:* no permite control de acceso granular por rol ni expiración automática
  de sesión, lo que incumpliría QS-04.

## Consecuencias

**Positivas:**
- Verificación de identidad y rol 100% local (sin consulta de BD por request): contribuye
  al rendimiento del escenario QS-02 y QS-03.
- Expiración configurable del token (campo `exp` del JWT): las sesiones caducan
  automáticamente sin intervención manual.
- Sin estado del lado del servidor: cualquier instancia del backend puede verificar
  cualquier token sin coordinación.

**Negativas / límites aceptados:**
- Un JWT emitido no puede revocarse antes de su expiración sin implementar una lista de
  tokens revocados (blacklist). Para el alcance actual (campus universitario, sesiones
  cortas) este límite es aceptable.
- La seguridad del mecanismo depende de la confidencialidad de `SECRET_KEY`. Está
  gestionada como secreto de GitHub Actions y variable de entorno del servidor de
  producción, nunca versionada en el repositorio.
