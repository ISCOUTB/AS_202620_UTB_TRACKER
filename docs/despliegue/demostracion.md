# Datos de demostración (exposición del lunes 23 de noviembre de 2026)

Todo es **ficticio**. Se carga solo al desplegar (migración `c4d5e6f7a8b9`, ADR-0021) sobre los 59
salones del catálogo: **no crea salones y no borra nada**. Se puede repetir sin duplicar.

## Qué se carga y cómo se reconoce

| Qué | Cómo se identifica |
|---|---|
| Equipos fijos (computadores, video beam, química…) | serial que empieza por `DEMO-` |
| Horarios de la semana | semestre `2026-2 DEMO` |
| 10 estudiantes ficticios y sus solicitudes, reportes y bitácora | correo `est01.demo@utb.edu.co` … `est10.demo@utb.edu.co` |
| Cuentas de ejemplo | `estudiante@utb.edu.co`, `auxiliar@utb.edu.co` (Auditor). **No** se crea ningún Administrador: se crea con `scripts/crear_admin.py` |
| Un salón deshabilitado para mostrar la habilitación | `A3-102` |

Las claves de las cuentas de ejemplo están solo en `scripts/cargar_demo_actividad.py`.

## No cargarla

Al correr `alembic upgrade head`, con la variable `CARGAR_DATOS_DEMO=0` la migración no hace nada.

## Limpiarla después de la exposición

En el servidor, desde la carpeta del proyecto y con el entorno de producción:

```bash
python scripts/cargar_demo_actividad.py --quitar --produccion
python scripts/cargar_equipos_demo.py --quitar --produccion
```

- La primera retira horarios, mantenimientos, solicitudes, reportes y bitácora de los estudiantes
  demo, y esos estudiantes. La segunda retira los equipos `DEMO-` y vuelve a habilitar `A3-102`.
- No toca las cuentas `estudiante@` y `auxiliar@`: desactívalas desde la pantalla Usuarios.
- Un equipo `DEMO-` con un reporte o mantenimiento que no sea de la demostración se conserva.
- Si no tienes acceso al servidor, se prepara una migración de limpieza equivalente.
