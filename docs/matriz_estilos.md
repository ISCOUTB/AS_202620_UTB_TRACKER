# Matriz comparativa de estilos arquitectónicos — UTB Tracker

Evaluación de los tres estilos evaluados (capas, hexagonal, monolito modular) contra las restricciones del proyecto y los escenarios de calidad definidos en `docs/arc42/` de UTB Tracker.

| | Capas | Hexagonal | Monolito modular |
|---|---|---|---|
| **Frontera** | Capa técnica (routers API / lógica de negocio / acceso a datos) | Puertos y adaptadores alrededor del núcleo de dominio | Módulo de dominio (`users`, `loans`, `resources`) |
| **Atributo que favorece en UTB Tracker** | Simplicidad inicial: estructura muy conocida y fácil de implementar para estudiantes. | Testabilidad y aislamiento absoluto de FastAPI y la persistencia (SQLAlchemy/Alembic). | Trabajo en paralelo e independencia: cada uno de los 4 integrantes puede desarrollar un módulo completo sin choques constantes en Git. |
| **Costo que introduce en UTB Tracker** | Alto acoplamiento técnico: un cambio en cómo se registra un préstamo obliga a modificar archivos en todas las capas. | Exceso de indirección y código boilerplate (interfaces de repositorios, adaptadores para SMTP, etc.) que consume tiempo valioso. | Disciplina de límites: requiere que el equipo defina bien las dependencias entre módulos para evitar importaciones circulares en Python. |
| **Se rompe cuando...** | El catálogo de recursos y flujos de préstamos crecen, volviendo complejas e inmanejables las tres capas técnicas genéricas. | El equipo no sostiene la abstracción de puertos bajo presión de tiempo académica. | No se respetan las fronteras entre módulos (por ejemplo, si el módulo de `loans` accede directamente a la base de datos de `resources` sin pasar por su servicio). |
| **Contraste contra QS-01 (disponibilidad en campus)** | Neutral: la disponibilidad depende de la infraestructura, pero la tolerancia a fallas de conexión queda dispersa en las capas. | Bueno en teoría para aislar la resiliencia en red, pero el costo de implementación no es realista para el tiempo del semestre. | Positivo: la lógica de tolerancia a fallas de red se encapsula dentro del módulo que la requiere (`loans`). |
| **Contraste contra QS-05 (usabilidad y desarrollo rápido)** | Neutral | Negativo: más capas de indirección significan más código de andamiaje y menos tiempo para pulir la experiencia de los formularios en la app móvil. | Positivo: FastAPI facilita modularizar el código mediante `APIRouter` y sub-módulos lógicos de manera muy directa. |
| **Encaje con restricciones (sección 2 de arc42)** | Encaja, pero dificulta la modularidad del equipo de 4. | No encaja con la restricción de tiempo ("terminar en el semestre académico", sección 2.2). | Encaja perfectamente con las restricciones organizacionales y técnicas (API REST en FastAPI + base de datos SQL con Alembic). |

## Conclusión

**Monolito modular** es el estilo elegido — ver justificación completa en
[`docs/adr/0001-estilo-arquitectonico.md`](adr/0001-estilo-arquitectonico.md).

Esta decisión se toma porque es el enfoque que permite el mayor desarrollo en paralelo para el equipo de 4 estudiantes, reduciendo la fricción y la indirección innecesaria que introduce una arquitectura hexagonal, mientras que ofrece una mayor separación de responsabilidades y modularidad que la arquitectura clásica de capas. Si el sistema de préstamos necesitara escalar a un microservicio en el futuro, los módulos ya estarían separados por dominio, haciendo la transición mucho más sencilla.
