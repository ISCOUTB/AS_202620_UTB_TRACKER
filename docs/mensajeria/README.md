# Módulo de Mensajería Asíncrona (Transactional Outbox)

## Descripción de la Solución en una Frase

Implementación del patrón **Transactional Outbox** y un **Worker** en segundo plano con semántica *at-least-once*, reintentos con backoff exponencial y deduplicación en el consumidor para desacoplar las notificaciones de préstamos sin comprometer la latencia ni la atomicidad ACID local del sistema.

---

## Índice de Documentación

1. **[Contrato de Evento de Dominio](contrato-prestamo-creado.md):** Especificación formal del evento `prestamo.creado` versión 1, esquema del sobre (envelope) y payload, y reglas de evolución y compatibilidad hacia atrás.
2. **[ADR-0006: Mensajería Asíncrona con Transactional Outbox](../adr/0006-mensajeria-asincrona-outbox.md):** Decisión arquitectónica que justifica la elección de Outbox frente a llamadas síncronas, `BackgroundTasks` o RabbitMQ, matizando el ADR-0003.
3. **[Evidencia de Ejecución](evidencia-ejecucion.md):** Salidas crudas de comandos de prueba (12 pruebas pasando), ciclo de vida de la migración de Alembic, traza de punta a punta del `message_id` y matriz de correspondencia con los puntos del enunciado.
4. **[Límites del Experimento](limites-del-experimento.md):** Análisis crítico de simplificaciones (notificador simulado, polling), aspectos pendientes para producción y reporte del estado de PostgreSQL y migraciones previas.
5. **[Arquitectura Global (arc42)](../arc42/arc42.md):** Actualización de la vista de ejecución con diagramas de secuencia y estados Mermaid (Sección 6), mapeo de componentes (Sección 7) y conceptos transversales (Sección 8.7).

---

## Cómo Ejecutar en PowerShell (Comandos Reales)

### 1. Ejecutar las pruebas automatizadas de mensajería (12 pruebas)
```powershell
.\venv\Scripts\python.exe -m pytest tests/test_messaging.py -v
```

### 2. Ejecutar la suite de pruebas de contrato congelado
```powershell
.\venv\Scripts\python.exe -m pytest tests/test_contract.py -v
```

### 3. Ejecutar la demostración interactiva de punta a punta (con base temporal aislada)
```powershell
.\venv\Scripts\python.exe scripts/demo_mensajeria.py
```

### 4. Ejecutar el worker de polling en modo standalone
```powershell
.\venv\Scripts\python.exe -m app.messaging.worker
```
*(Nota: Requiere que la base de datos configurada en `DATABASE_URL` contenga las tablas creadas por Alembic o `Base.metadata.create_all`).*

---

## Enlace al Commit

`<PEGAR URL DEL COMMIT>`
