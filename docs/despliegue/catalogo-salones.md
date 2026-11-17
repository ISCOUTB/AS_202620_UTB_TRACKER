# Cargar el catálogo de salones UTB (ADR-0021)

**Estado de la lista: PROVISIONAL.** Falta confirmarla con Planta Física o con Registro
Académico. No hay un listado oficial completo publicado. La lista se armó así:

- se partió de la lista que dio el equipo;
- se corrigió con una tesis de la biblioteca de la UTB
  ([Ramírez León, 2007](https://biblioteca.utb.edu.co/notas/tesis/0043111.pdf)). Esa tesis
  nombra los salones A1-402 a A1-407 del piso 4 de Aulas 1.

## Qué trae

Son 59 salones, con códigos `A<edificio>-<piso><salón>` (A1-101 = edificio A1, piso 1,
salón 01).

| Edificio | Pisos y salones |
|---|---|
| A1 | piso 1: 101–104 · piso 2: 201–205 · piso 3: 301–305 (supuesto) · piso 4: 401–407 |
| A2 | pisos 2 a 5: x01–x05 |
| A3 | piso 1: 101–103 · piso 2: 201–203 |
| A4 | piso 1: 101–104 · piso 2: 201–204 |
| A5 | piso 2: 201–204 (supuesto: solo ese piso) |

- **Capacidad:** todos quedan con 40 marcada como **estimada**, porque no hay un dato oficial.
  En la app se ve "(estimado)" hasta que alguien escribe la capacidad real.
- **Tipo:** A1-402 a A1-407 quedan como laboratorio de cómputo, porque la tesis los llama
  salas de informática. Hay que confirmarlo. Los demás quedan como aula.

## Corregir la lista

Edita `scripts/datos/catalogo_utb.json`, que tiene los rangos, los tipos y la fuente de cada
dato. No hay que tocar código. Después vuelve a correr la carga: crea los salones que falten y
nunca borra.

Si un salón no existe, desactívalo desde la app (**Perfil → Catálogo de salones →** botón de
desactivar). No se borra, y su historial se conserva.

## Opción A: desde la app (recomendada en producción)

1. Entra con una cuenta de **Administrador**.
2. Ve a **Perfil → Administración → Catálogo de salones**.
3. Toca **Crear varios**. Elige el edificio, el piso, "desde" y "hasta", y toca
   **Ver vista previa**.
4. Revisa la lista: los salones que ya existen no se tocan. Luego toca **Confirmar**.
5. Repite el paso 3 y el 4 por cada fila de la tabla de arriba.

Todo queda en la bitácora de auditoría (`salon.crear_lote`).

## Opción B: con el script (en el servidor, a mano)

Necesitas estar en la carpeta del proyecto, en el servidor, con su `.env`.

```powershell
# 1) Primero, solo ver qué haría (no escribe nada):
.\venv\Scripts\python scripts\cargar_catalogo_utb.py --simular
# 2) Si se ve bien, aplicar:
.\venv\Scripts\python scripts\cargar_catalogo_utb.py
```

En Linux (el servidor), usa `venv/bin/python` en lugar de `.\venv\Scripts\python`.

Desde el 2026-11-16 la migración `f2a3b4c5d6e7` carga este catálogo en la nube al desplegar (solo crea los que faltan, nunca borra). El script sirve para cargar una lista corregida después.

## Salones "fuera del catálogo"

La pantalla del catálogo y el script muestran los salones que ya existían y no siguen la regla.
Pueden ser datos viejos, datos de ejemplo o espacios especiales. Cada uno trae una propuesta:

- **No sigue el formato** (por ejemplo, "ALC-201"): déjalo como espacio especial o desactívalo
  si no existe. Si **tiene historial**, no lo borres.
- **El edificio o el piso no coinciden** con el código: corrígelos en la app (solo el
  Administrador puede).
- **El código es válido pero no está en la lista:** confírmalo con Planta Física. Si existe,
  agrégalo al JSON.

Nada de esto se hace solo. Decide el Administrador.
