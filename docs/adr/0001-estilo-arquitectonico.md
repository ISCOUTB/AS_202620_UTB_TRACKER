# 0001 - Estilo arquitectónico: Monolito Modular

## Estado

Aceptado

## Contexto

Tractar tiene que construirse en un semestre académico con un equipo de 4 personas que
además cursan otras materias (restricción organizacional, sección 2.2 de arc42). El stack
está condicionado a HTML + MySQL con las herramientas dadas por el profesor (restricción
técnica, sección 2.1), y el equipo ya viene trabajando sobre Django.

El escenario de calidad que más presiona esta decisión es
[QS-01 (disponibilidad / trabajo offline)](../arc42/10_requisitos_calidad.md#qs-01--disponibilidad):
el conductor debe poder seguir registrando viajes sin conexión y sincronizar después, lo cual
obliga a que la lógica de sincronización quede encapsulada y no dispersa por todo el sistema.
También pesa [QS-05 (usabilidad)](../arc42/10_requisitos_calidad.md#qs-05--usabilidad): el
tiempo de desarrollo que se gaste en indirección arquitectónica es tiempo que no se gasta en
que el formulario sea simple de usar.

Este ADR corresponde al aspecto
[A-02 (Acceso al sistema durante la jornada laboral)](../aspectos.md) y, de forma transversal,
a todos los aspectos declarados en `docs/aspectos.md`, porque la decisión de estilo afecta
la estructura completa del código, no un solo módulo.

## Decisión

Se organiza Tractar como un **monolito modular** sobre Django: un único desplegable, dividido
internamente en módulos de dominio independientes (`apps/usuarios`, `apps/vehiculos`,
`apps/viajes`, `apps/facturacion`), cada uno con su propia frontera de responsabilidad.

## Alternativas consideradas

**Capas (N-tier).** Se descartó porque la sincronización offline es un requisito que
atraviesa presentación, lógica y persistencia a la vez; en una arquitectura por capas
técnicas, cada ajuste a esa sincronización obligaría a tocar las tres capas en simultáneo,
lo que va directamente en contra de QS-01.

**Hexagonal (puertos y adaptadores).** Se descartó por costo/tiempo, no por ser mala idea en
abstracto. El equipo son 4 estudiantes con un semestre y sin experiencia previa sosteniendo
puertos y adaptadores bajo presión de entrega; el riesgo real es que la abstracción se rompa
a mitad de camino y termine costando más de lo que aporta. Ver matriz completa en
`docs/matriz_estilos.md`.

## Consecuencias

**Se gana:** cada módulo de dominio puede evolucionar con bajo choque entre los 4 integrantes
(uno puede trabajar en `viajes` mientras otro trabaja en `facturacion` sin pisarse), y el
estilo no pelea con Django, que ya está pensado para organizarse en apps.

**Se asume:** el monolito modular solo funciona si el equipo respeta la frontera entre
módulos (por ejemplo, que `viajes` no importe directamente modelos internos de
`facturacion`). Esa disciplina no la impone el framework, la tiene que sostener el equipo
en revisión de código.

**Deuda aceptada a sabiendas:** si Tractar creciera más allá del alcance de un proyecto de
gremio local (por ejemplo, si varias empresas grandes lo adoptaran a la vez), el monolito
modular no escalaría los módulos de forma independiente. Se acepta ese límite porque está
fuera del alcance actual (ver sección 1.1 de arc42: "dirigido a propietarios independientes,
no a grandes empresas todavía").
