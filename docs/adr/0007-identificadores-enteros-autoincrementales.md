# ADR-0007: Uso de Identificadores Enteros Autoincrementales en Claves Primarias

## Estado

Aceptado (Registrado de forma retroactiva para formalizar la decisión arquitectónica implementada en el repositorio desde la concepción del modelo de datos).

## Fecha

25 de octubre de 2026

## Contexto

Desde las fases tempranas del desarrollo de UTB Tracker (Semanas 1 a 4, formalizado en la migración de stack en [ADR-0002](0002-cambio-stack-fastapi-flutter.md)), se adoptó el estándar convencional de PostgreSQL y SQLAlchemy de definir identificadores de clave primaria como enteros autoincrementales de 32 bits (`Column(Integer, primary_key=True, index=True)`).

Esta decisión modeló transversalmente todo el sistema: tablas de la base de datos, relaciones de clave foránea, esquemas de transferencia Pydantic, contratos de enrutamiento REST y el cliente móvil desarrollado en Flutter. Sin embargo, no se redactó en su momento un registro de decisión arquitectónica (ADR) que sopesara formalmente sus implicaciones de acoplamiento, seguridad y escalabilidad frente a identificadores universalmente únicos (UUIDs) u opacos.

## Decisión

Se formaliza la decisión de mantener el uso de **identificadores enteros autoincrementales (`INTEGER SERIAL` / `Identity`)** para las entidades del dominio de UTB Tracker (`usuarios`, `recursos`, `prestamos`, `salones`, `prestamos_salon`, `horarios_disponibilidad`, `reportes_dano` y `mensajes_outbox`).

Los identificadores numéricos se exponen de forma directa tanto en la capa de persistencia interna como en las URLs públicas de la API REST (`/resources/{recurso_id}`, `/salones/{salon_id}`, etc.) y en el estado de la aplicación móvil Flutter.

## Alternativas Evaluadas

1. **UUID v4 (Identificador Aleatorio de 128 bits):**
   - *Ventajas:* Descentralización total (pueden generarse en el cliente Flutter sin consultar a la BD); indescifrables e imposibles de enumerar por fuerza bruta.
   - *Descarte:* Desorden aleatorio en inserciones que fragmenta severamente los árboles B-Tree en PostgreSQL; mayor consumo de almacenamiento (16 bytes vs 4 bytes) y peor rendimiento de caché de disco en índices; URLs extensas y poco amigables para operadores de laboratorio.
2. **UUID v7 / ULID (Secuenciales ordenados por tiempo):**
   - *Ventajas:* Combina la no-colisión distribuida con localidad temporal, evitando la fragmentación del índice B-Tree.
   - *Descarte:* Soporte nativo limitado en bibliotecas estándar de Python 3.12 y SQLite en el momento de la concepción del proyecto; sobrecarga innecesaria para un sistema centralizado en una única base de datos relacional.
3. **Clave subrogada entera interna + Identificador público opaco (NanoID/UUID público):**
   - *Ventajas:* Máxima eficiencia en joins internos (`INTEGER`) protegiendo las URLs públicas contra enumeración.
   - *Descarte:* Complejidad de doble columna en cada tabla, doble indexación y necesidad de traducir identificadores en cada endpoint y repositorio de Flutter.

## Costo de Revertir Cuantificado (Por qué es la Decisión Más Costosa)

Migrar de claves enteras autoincrementales a identificadores UUID/opacos es **la decisión de datos más costosa de revertir de todo el repositorio**, superando por órdenes de magnitud a cualquier otra deuda técnica. El impacto verificado en el código comprende:

- **10 Claves Primarias:** 8 tablas con PK entero autoincremental (`id = Column(Integer, primary_key=True)`) en `app/models/auth_models.py:18`, `recurso_models.py:22,47,82`, `salon_models.py:28,54,71` y `app/messaging/models.py:36` (más 2 tablas con clave String: `configuracion:67` y `notificaciones_procesadas:81`).
- **9 Claves Foráneas Estrictas:** Todas las relaciones (`recursos.salon_id`, `prestamos.recurso_id`, `prestamos.usuario_id`, `configuracion.prestamo_id`, `reportes_dano.recurso_id`, `reportes_dano.usuario_id`, `horarios_disponibilidad.salon_id`, `prestamos_salon.salon_id`, `prestamos_salon.usuario_id`) enlazan enteros de 32 bits (`app/models/recurso_models.py:24,48,49,69,83,84` y `salon_models.py:55,72,73`). Alterar el tipo exige recrear la totalidad de restricciones de integridad referencial.
- **16 Endpoints REST:** 16 rutas en controladores FastAPI definen `{.*_id}` numérico en su ruta (`app/routers/auth.py:43,53`, `horarios.py:57,67,78`, `loans.py:65`, `prestamos_salon.py:59`, `resources.py:56,71,88,99,117`, `salones.py:46,56,67,77`).
- **14 Archivos en Flutter (`frontend/lib/`):** 14 archivos entre repositorios, controladores, entidades y widgets (`features/prestamos/data/prestamos_data.dart`, `recursos_data.dart`, `salones_data.dart`, etc.) tipifican `int id` y concatenan IDs en peticiones HTTP.
- **Migración de Datos en Caliente:** Requeriría transformar millones de enteros a UUIDs preservando integridad relacional histórica y compatibilidad con clientes móviles instalados.

### Comparativa de Costo de Reversión frente a otras decisiones de datos

| Decisión de Datos Alternativa | Costo de Reversión en UTB Tracker |
|---|---|
| **Estado redundante en `recursos.estado`** | Bajo: Eliminar la columna `recursos.estado` y calcular disponibilidad mediante consulta `JOIN` a `prestamos` activos requiere modificar solo ~2 archivos de servicio (`loans.py`, `resources.py`). |
| **Columnas de estado sin restricción `CHECK`** | Bajo: Agregar `CheckConstraint("estado IN ('disponible', 'prestado', 'dañado', 'mantenimiento')")` es una migración simple de DDL en Alembic sin alterar código de aplicación ni APIs. |
| **Campos `DateTime` sin zona horaria (`timezone=False`)** | Medio: Modificar `DateTime(timezone=True)` requiere una migración SQL agregando `AT TIME ZONE 'UTC'` y no afecta la estructura de las rutas ni el tipado de clientes. |
| **Tabla outbox en la misma BD de negocio** | Medio: Extraer el outbox hacia RabbitMQ o Redis altera únicamente el módulo `app/messaging/` (~4 archivos) sin tocar modelos de negocio ni el frontend Flutter. |
| **`create_all()` vs Migraciones Alembic** | Medio: Generar la migración base limpia y ejecutar `alembic upgrade head` en el despliegue es un cambio operacional aislado en `alembic/versions/`. |
| **Identificadores Enteros Autoincrementales** | **Extremo (Crítico):** Afecta 10 tablas, 9 FKs, 16 endpoints, 14 archivos de frontend, esquemas OpenAPI y almacenamiento local SQLite/SharedPreferences del cliente móvil. |

## Consecuencias

### Positivas
- **Máxima Eficiencia Relacional:** Claves de 4 bytes ocupan un espacio mínimo en disco y memoria RAM. Los índices B-Tree se mantienen perfectamente compactos y sin fragmentación de páginas durante inserciones intensivas.
- **Rendimiento de Consultas (`JOIN`):** Las comparaciones numéricas entre claves primarias y foráneas se ejecutan a velocidad nativa de CPU, satisfaciendo los requisitos de latencia en horas pico (QS-02, QS-03).
- **Legibilidad y Ergonomía:** URLs concisas (`/resources/5`) y facilidad para pruebas manuales y depuración por parte de los auxiliares de laboratorio (QS-05).

### Negativas y Brecha de Seguridad Verificada
- **Enumeración de Entidades e Inseguridad Directa (V3):**  
  Al ser enteros secuenciales predecibles (1, 2, 3...), cualquier usuario puede deducir la existencia de registros vecinos.  
  *Vulnerabilidad concreta verificada en el código:* En `app/routers/auth.py:53-59`:
  ```python
  @router.get("/user/{user_id}", response_model=UserResponse)
  def get_user_endpoint(
      user_id: int,
      db: Annotated[Session, Depends(get_db)],
      current_user: CurrentUser,
  ):
      return auth_service.get_user_by_id(db, user_id)
  ```
  La dependencia `current_user: CurrentUser` únicamente verifica que el solicitante presente un token JWT válido, pero **no valida que `user_id == current_user.id` ni exige privilegios de administrador**. Debido a que los IDs son enteros secuenciales, cualquier usuario autenticado (incluso un estudiante con rol `usuario_utb`) puede iterar desde `1` hasta $N$ y descargar la lista completa de usuarios del campus con sus nombres, correos institucionales y roles.
- **Fuga de Métricas de Negocio:** La observación del ID del último préstamo revela a terceros la cantidad exacta de operaciones realizadas por la universidad.
- **Acoplamiento de Fronteras:** Impide a clientes móviles generar registros en modo fuera de línea (*offline-first*), ya que el ID solo puede ser dictaminado por la secuencia central de PostgreSQL.
