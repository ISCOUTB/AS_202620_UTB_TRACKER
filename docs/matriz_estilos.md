# Matriz comparativa de estilos arquitectónicos — Tractar

Evaluación de los tres estilos vistos en la sesión (capas, hexagonal, monolito modular)
contra las restricciones reales del proyecto y los escenarios de calidad definidos en
`docs/arc42/` sección 10.

| | Capas | Hexagonal | Monolito modular |
|---|---|---|---|
| **Frontera** | Capa técnica (presentación / lógica / datos) | Puertos y adaptadores alrededor del dominio | Módulo de dominio (usuarios, vehículos, viajes, facturación) |
| **Atributo que favorece en Tractar** | Simplicidad inicial — útil si el equipo fuera nuevo en el dominio | Testabilidad y sustitución de adaptadores — útil si esperáramos cambiar de proveedor de datos o de canal de entrada | Evolución gradual con separación clara por dominio — cada aspecto (A-01 a A-05) puede evolucionar con bajo choque entre los 4 integrantes |
| **Costo que introduce en Tractar** | Cambios transversales: la sincronización offline (QS-01) atraviesa presentación, lógica y datos a la vez, así que en capas tocaría las tres capas por cada ajuste | Más indirección: puertos/adaptadores para MySQL y para la cola de sincronización offline añaden código de andamiaje que el equipo no tiene tiempo de mantener en un semestre | Disciplina de límites: exige que el equipo respete la frontera entre módulos (por ejemplo, que `viajes` no importe directamente modelos de `facturacion`) |
| **Se rompe cuando...** | El dominio (afiliación, historial, offline) crece más que las 3 capas genéricas — que es justamente el caso de Tractar | El equipo no sostiene la abstracción de puertos bajo presión de tiempo — riesgo real con 4 personas y un semestre | Nadie vigila el acoplamiento entre módulos — mitigable con revisión de PR entre los 4 integrantes |
| **Contraste contra QS-01 (disponibilidad/offline)** | Malo: la lógica de sincronización queda dispersa en las 3 capas | Bueno en teoría, pero el costo de implementarlo bien no es realista en el tiempo disponible | Aceptable: la sincronización se encapsula como responsabilidad propia dentro de cada módulo que la necesita |
| **Contraste contra QS-05 (usabilidad, tiempos de entrega)** | Neutral | Negativo: más capas de indirección = más tiempo de desarrollo, menos tiempo para pulir el formulario simple que pide QS-05 | Positivo: Django (el framework que ya usa el equipo) está diseñado para monolitos modulares por app, así que no se pelea con la herramienta |
| **Encaje con restricciones (sección 2 de arc42)** | Encaja, pero no resuelve bien la restricción de offline-first | No encaja con "equipo de 4, terminar en un semestre" (sección 2.2) | Encaja con las restricciones técnicas (HTML + MySQL vía Django) y organizacionales (equipo pequeño, tiempo limitado) |

## Conclusión

**Monolito modular** es el estilo elegido — ver justificación completa en
[`docs/adr/0001-estilo-arquitectonico.md`](adr/0001-estilo-arquitectonico.md).

No porque sea "mejor" en abstracto, sino porque es el que menos compromisos rotos deja
contra las restricciones y escenarios de calidad *reales* de Tractar. Si el equipo creciera
o el proyecto necesitara escalar por separado cada módulo, esta decisión se reevaluaría
(quedaría un ADR nuevo marcando este como superado).
