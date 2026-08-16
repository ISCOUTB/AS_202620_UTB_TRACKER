# Ficha del problema — Tractar

**Equipo:** Geronimo Cadena, Sebastian Garcia, Mateo Milán, Joriel Barros
**Materia:** Arquitectura de Software
**Fecha:** 09/08/2026

## Problema

Los propietarios de vehículos de carga pesada en Cartagena llevan el registro de los viajes de
forma manual: el conductor anota los datos en papel, se lo entrega al propietario, y este pasa
la información a mano para armar el historial y la facturación. Este proceso consume entre 1 y
2 horas por viaje, y es propenso a pérdida de información y errores.

## A quién afecta

- **Propietarios** de vehículos de carga pesada, que necesitan el historial completo de sus
  vehículos para facturar y tomar decisiones, muchos con conocimientos tecnológicos básicos.
- **Conductores**, empleados de los propietarios, con conocimiento tecnológico limitado, que
  deben registrar cada viaje.

## Por qué importa ahora

El proceso manual no escala: no hay trazabilidad confiable, el propietario pierde horas por
viaje procesando papel, y la información se puede perder si el conductor se desvincula antes
de entregarla.

## Qué se propone

Tractar: una aplicación web que digitaliza el registro de viajes. Permite a conductores
llenar un formulario de viaje (con soporte offline que sincroniza al recuperar conexión), a
propietarios gestionar vehículos y afiliaciones, y genera automáticamente un documento Excel
con el historial para facturación. El historial se conserva aunque el conductor se desvincule
del vehículo.

## Alcance de esta entrega

Repositorio `AS_202620_TRACTAR` sin poder incluirlo todavia a la organización ISCOUTB, con los integrantes como
colaboradores, `docs/aspectos.md` con el aspecto de calidad declarado (usabilidad), y
`docs/ia.md`.
