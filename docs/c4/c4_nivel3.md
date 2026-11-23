# Diagrama de Componentes (C4 - Nivel 3) · API Backend · UTB Tracker

Este diagrama descompone el contenedor **API Backend** (FastAPI) en sus componentes internos de diseño y arquitectura, siguiendo el patrón de **monolito modular por capas** documentado en [ADR-0001](../adr/0001-estilo-arquitectonico.md) y en [arc42 sección 5](../arc42/arc42.md#5-estructura-del-sistema).

---

## 1. Mapeo de Capas y Componentes

| Componente | Paquete / Ruta | Responsabilidad |
|---|---|---|
| **Middleware & Core** | `app/main.py`, `app/core/` | CORS, logging estructurado con `request_id`, configuración (`config.py`), seguridad JWT (`security.py`, `hashing.py`) y motor SQLAlchemy (`database.py`). |
| **Routers (Adaptadores HTTP)** | `app/handler/` | Endpoints REST: deserializan DTOs, validan con Pydantic, aplican inyección de dependencias (`Depends`) y autorizan por roles/permisos. (`auth`, `salones`, `salones_admin`, `catalogo`, `estado_salon`, `horarios`, `prestamos_salon`, `auditoria`, `usuarios`, `stats`, `health`). |
| **Servicios de Dominio** | `app/service/` | Lógica de negocio transaccional: reglas de disponibilidad, bloqueo pesimista `.with_for_update()`, hashing, validaciones de dominio y publicación en outbox. |
| **Modelos de Persistencia (ORM)** | `app/models/` | Entidades mapeadas en SQLAlchemy: `Usuario`, `Salon`, `Recurso`, `Horario`, `PrestamoSalon`, `Auditoria`, `IdempotenciaRegistro`. |
| **Outbox & Messaging** | `app/messaging/` | Patrón *Transactional Outbox*: inserción transaccional en `mensajes_outbox` y worker asíncrono con backoff exponencial y jitter para entrega SMTP / FCM. |

---

## 2. Diagrama Mermaid (C4 Component Diagram)

```mermaid
graph TB
    linkStyle default fill:#ffffff

    subgraph C4_Nivel3 ["Diagrama de Componentes (C4 Nivel 3) - API Backend"]
        style C4_Nivel3 fill:#f8f9fa,stroke:#0b4884

        Client["App Móvil Flutter / Swagger UI<br><b>[HTTPS / JSON]</b>"]
        style Client fill:#438dd5,stroke:#2e6295,color:#ffffff

        subgraph Backend ["Contenedor: API Backend (FastAPI)"]
            style Backend fill:#ffffff,stroke:#1168bd

            MW["<b>Middleware & Filtros</b><br>CORS, Logging estructurado,<br>X-Request-ID, Manejador 422"]
            style MW fill:#1168bd,stroke:#0b4884,color:#ffffff

            subgraph RoutersLayer ["Capa de Routers (HTTP Adapters)"]
                style RoutersLayer fill:#e8f4fd,stroke:#438dd5
                R_Auth["auth.py<br>Login, Registro, Correo, Perfil"]
                R_Salones["salones.py / salones_admin.py<br>Ocupación, Catálogo, Estado"]
                R_Prestamos["prestamos_salon.py<br>Solicitudes, Aprobación"]
                R_Audit["auditoria.py / usuarios.py<br>Bitácora inmutable, Roles"]
                R_Health["health.py<br>/salud (Smoke test DB)"]
            end

            subgraph ServicesLayer ["Capa de Servicios de Dominio"]
                style ServicesLayer fill:#e8f4fd,stroke:#438dd5
                S_Auth["services/auth.py<br>Bcrypt, Tokens de un solo uso"]
                S_Salones["services/salones.py<br>Cálculo de ocupación y equipos"]
                S_Prestamos["services/prestamos_salon.py<br>Transacciones, Idempotencia"]
                S_Audit["services/auditoria.py<br>Registro transaccional de auditoría"]
                S_Outbox["messaging/outbox.py<br>Publicador de eventos a outbox"]
            end

            subgraph ModelsLayer ["Capa de Persistencia (SQLAlchemy)"]
                style ModelsLayer fill:#e8f4fd,stroke:#438dd5
                ORM["Modelos ORM<br>Usuario, Salon, PrestamoSalon,<br>Auditoria, MensajeOutbox"]
            end
        end

        DB[("<b>PostgreSQL 16</b><br>[Base de Datos Relacional]")]
        style DB fill:#08427b,stroke:#052e56,color:#ffffff

        Worker["<b>Worker Outbox</b><br>[messaging/worker.py]<br>Consumidor asíncrono"]
        style Worker fill:#438dd5,stroke:#2e6295,color:#ffffff

        SMTP["<b>Servidor SMTP</b><br>[Servicio Externo]"]
        style SMTP fill:#999999,stroke:#666666,color:#ffffff

        Client -->|HTTPS / JSON| MW
        MW --> R_Auth & R_Salones & R_Prestamos & R_Audit & R_Health

        R_Auth --> S_Auth
        R_Salones --> S_Salones
        R_Prestamos --> S_Prestamos
        R_Audit --> S_Audit

        S_Prestamos --> S_Outbox
        S_Auth --> S_Outbox

        S_Auth & S_Salones & S_Prestamos & S_Audit & S_Outbox --> ORM
        ORM -->|TCP / SQL (Pool SQLAlchemy)| DB

        Worker -->|Lectura / Actualización de estado| DB
        Worker -->|Envío de correos de verificación y avisos| SMTP
    end
```

---

## 3. Principios de Diseño Verificados

1. **Inversión y dirección de dependencias:** La capa HTTP (`routers`) depende de la capa de lógica de negocio (`services`), y los servicios interactúan con la capa de persistencia (`models` / SQLAlchemy). No existen dependencias circulares (validado por `tests/test_erosion_capas.py`).
2. **Atomicidad con Outbox:** Las notificaciones (correos y eventos) nunca se envían de forma sincrónica durante la petición HTTP para evitar transacciones distribuidas (2PC) o pérdida de eventos si el servicio SMTP se cae; se persisten en `mensajes_outbox` dentro de la misma transacción de PostgreSQL (ADR-0006).
3. **Idempotencia y Prevención de Concurrencia:** Las reservas y solicitudes críticas emplean bloqueos pesimistas a nivel de base de datos (`.with_for_update()`) y soporte para claves `X-Idempotency-Key` (ADR-0001, ADR-0010, QS-06).
