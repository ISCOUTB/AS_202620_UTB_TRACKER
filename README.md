# Tractar

Sistema de registro de viajes para el gremio de camioneros de Cartagena. Ver `docs/arc42/`
para la documentación de arquitectura completa.

## Cómo arrancar (un solo comando)

```bash
./run.sh
```

Esto crea el entorno virtual si no existe, instala las dependencias, aplica migraciones,
corre las pruebas y levanta el servidor en `http://127.0.0.1:8000`.

Para confirmar que el esqueleto responde:

```bash
curl http://127.0.0.1:8000/salud/
# {"status": "ok", "proyecto": "Tractar"}
```

## Estructura (Monolito Modular)

La organización del código sigue el estilo decidido en
[`docs/adr/0001-estilo-arquitectonico.md`](docs/adr/0001-estilo-arquitectonico.md):
módulos de dominio independientes dentro de un único desplegable.

```
config/             # configuración del proyecto Django (settings, urls)
apps/
  core/              # infraestructura transversal (health check, utilidades)
  usuarios/          # propietarios y conductores
  vehiculos/         # vehículos y afiliación de conductores
  viajes/            # registro y estado de viajes
  facturacion/       # pagos/no pagos y exportación a Excel
```

Cada módulo en `apps/` es la frontera de un aspecto (ver `docs/aspectos.md`). Todavía no
tienen modelos ni lógica de negocio: eso se implementa en las semanas siguientes según el
cronograma del curso — esta entrega (S3) solo deja la fontanería lista.

## Pruebas

```bash
./venv/bin/python manage.py test
```

Actualmente hay 1 prueba: confirma que el servidor arranca y el endpoint de salud responde.
