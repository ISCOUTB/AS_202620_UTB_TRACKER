# Guía de pruebas con datos de ejemplo

Esto es **solo para tu computador (desarrollo)**. El script se niega a correr si
`ENVIRONMENT=production`. Los datos de ejemplo nunca van a la nube.

## Cargar los datos

```powershell
.\venv\Scripts\python scripts\seed_demo.py               # crea o actualiza los datos de ejemplo
.\venv\Scripts\python scripts\seed_demo.py --reiniciar   # VACÍA la base LOCAL (todas las cuentas) y siembra de nuevo
.\venv\Scripts\python scripts\cargar_catalogo_utb.py     # opcional: los 59 salones del catálogo
.\iniciar.ps1                                            # API + worker + app web locales
```

Vuelve a correr `seed_demo.py` para que las clases coincidan con la hora actual.

## Cuentas (las claves están SOLO en `scripts/seed_demo.py`)

| Para probar | Cuenta |
|---|---|
| Administrador: todo, más usuarios, catálogo, bitácora, estadísticas y modo prueba | `admin@utb.edu.co` |
| Auditor: panel, solicitudes, control, equipos y habilitación | `auxiliar@utb.edu.co` |
| Estudiante: pedir salones y ver mis solicitudes | `estudiante@utb.edu.co` (también `camila`, `andres`, `valentina`) |
| Correo sin verificar (no puede solicitar) | `sinverificar@utb.edu.co` |

## Qué debe verse por rol

- **Estudiante:** barra con Inicio, Salones, Mis solicitudes y Perfil.
  - **A1-201** sale "Deshabilitado: Mantenimiento…", con su fecha y sin el botón Solicitar.
  - Un salón "Ocupado ahora" **sí** se puede pedir para otra hora.
  - En "Mis solicitudes" hay solicitudes en todos los estados: pendiente, aprobada, rechazada
    con motivo, en uso, finalizada y cancelada.
- **Auditor:** Salones (panel) muestra los chips "libres ahora" por piso. El menú **⋮** tiene
  "Habilitar o deshabilitar varios" (con vista previa) y "Copiar CSV".
  - En el detalle de un salón están Habilitación, Equipos (selector Operativo, Dañado o En
    mantenimiento), Agregar equipo, Aplicar plantilla e Historial.
  - **No** ve Usuarios, Bitácora ni Catálogo. Si los abre por enlace, sale "No tienes acceso".
- **Administrador:** lo mismo que el Auditor, más: Perfil → Catálogo de salones (crear uno,
  crear varios con vista previa, fuera del catálogo, desactivar), Usuarios, Roles por correo,
  Estadísticas, Bitácora y Modo prueba.

## Casos límite sembrados

1. **Salón deshabilitado con una solicitud afectada.** A1-201 está en mantenimiento y tiene una
   solicitud pendiente de Andrés. En la bandeja del Auditor sale con el aviso; aprobarla da
   error y rechazarla sí se puede.
2. **Conflicto de horario.** Las solicitudes pendientes que chocan con una clase muestran
   "Choca con…" en la bandeja.
3. **Equipo dañado con un reporte abierto.** El video beam de A1-201 está dañado, y A4-204 y
   A1-104 tienen reportes de equipo abiertos. Si marcas un equipo como dañado, la app ofrece
   vincular uno de esos reportes o abrir otro: no lo hace sola.
4. **Correo sin verificar.** Con `sinverificar@utb.edu.co`, pedir un salón da error hasta
   verificar el correo.

## Flujo completo para probar a mano

1. Entra como estudiante y pide un salón libre.
2. Entra como auditor y aprueba la solicitud en la bandeja.
3. Vuelve al estudiante: la solicitud sale "aprobada". El correo queda en el outbox. Con el
   worker corriendo y sin correo real, se escribe en la carpeta de correos de desarrollo.

Luego prueba el caso de un salón cerrado:

1. Como auditor, deshabilita ese salón.
2. El estudiante ve el aviso en su solicitud y recibe el correo "salón deshabilitado".
