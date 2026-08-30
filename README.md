# UTB Tracker

Sistema de control de inventario y gestión de préstamos de recursos electrónicos y de laboratorios para la Universidad Tecnológica de Bolívar (UTB).

Ver `docs/arc42/` para la documentación completa del diseño de arquitectura.

---

## Cómo arrancar (un solo comando)

Para levantar el proyecto de forma automática, ejecuta:

```bash
chmod +x run.sh  # (Opcional, en entornos Unix para dar permisos de ejecución)
./run.sh
```

Este script:
1. Crea el entorno virtual (`venv`) si no existe.
2. Instala las dependencias necesarias de FastAPI, Pytest y HTTPX.
3. Ejecuta las pruebas unitarias automatizadas.
4. Inicia el servidor de desarrollo local en `http://127.0.0.1:8000`.

### Confirmar funcionamiento del esqueleto
Una vez levantado el servidor, el endpoint de salud debe responder:

```bash
curl http://127.0.0.1:8000/salud/
# Respuesta esperada: {"status": "ok", "proyecto": "UTB Tracker"}
```

---

## Estructura del Código (Monolito Modular)

La estructura del código sigue el estilo arquitectónico de **Monolito Modular** sobre **FastAPI**, tal como se define en el [ADR-0001](docs/adr/0001-estilo-arquitectonico.md). El código se divide en módulos de dominio independientes bajo la carpeta `app/`:

```
app/
  main.py              # Inicialización de FastAPI, configuración de middlewares y montaje de rutas
  routers/
    __init__.py
    users.py           # Gestión de usuarios, autenticación y roles (A-01)
    loans.py           # Registro de préstamos y devoluciones de equipos (A-02)
    resources.py       # Catálogo de objetos electrónicos y salones (A-05)
  tests/
    __init__.py
    test_main.py       # Pruebas automatizadas (valida arranque y salud del servidor)
```

Cada archivo dentro de `routers/` representa la frontera física de un aspecto de calidad del dominio de negocio (detallados en [aspectos.md](docs/aspectos.md)). Actualmente, no contienen lógica de negocio compleja, permitiendo que la fase de desarrollo inicie directamente sobre la arquitectura propuesta.

---

## Pruebas Automatizadas

Las pruebas unitarias se ejecutan de forma automática al correr `./run.sh`, pero si deseas ejecutarlas de forma independiente con el entorno virtual activo, puedes correr:

```bash
python -m pytest app/tests/
```

Actualmente, el repositorio cuenta con una prueba unitaria inicial en verde que verifica el endpoint `/salud/` de forma integral usando el `TestClient` de FastAPI.
