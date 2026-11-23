import '../../../core/network/api_client.dart';
import '../../../core/utils/utilidades.dart';
import '../domain/disponibilidad.dart';

/// JSON de la habilitación y los equipos del salón (ADR-0022) → entidades.
class DisponibilidadRepositoryImpl implements DisponibilidadRepository {
  DisponibilidadRepositoryImpl(this._api);
  final ApiClient _api;

  static String _fecha(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static List<String> _textos(Object? v) => [for (final x in (v as List? ?? const [])) '$x'];

  Map<String, dynamic> _habilitacion(DatosHabilitacion d) => {
        'habilitado': d.habilitado,
        if (!d.habilitado && d.motivo != null) 'motivo': d.motivo!.api,
        if (!d.habilitado && (d.nota ?? '').trim().isNotEmpty) 'nota': d.nota!.trim(),
        if (!d.habilitado && d.reapertura != null) 'reapertura_estimada': _fecha(d.reapertura!),
      };

  @override
  Future<int> cambiarHabilitacion(int salonId, DatosHabilitacion datos) async {
    final r = await _api.patch('/salones/$salonId/habilitacion', cuerpo: _habilitacion(datos))
        as Map<String, dynamic>;
    return (r['solicitudes_afectadas'] as List? ?? const []).length;
  }

  @override
  Future<List<EntradaHistorial>> historial(int salonId) async {
    final lista = await _api.get('/salones/$salonId/historial') as List<dynamic>;
    return [
      for (final e in lista.cast<Map<String, dynamic>>())
        EntradaHistorial(
          accion: (e['accion'] ?? '').toString(),
          descripcion: (e['descripcion'] ?? '').toString(),
          creadoEn: parsearFechaServidor(e['creado_en'].toString()),
          actorNombre: e['actor_nombre'] as String?,
        ),
    ];
  }

  @override
  Future<List<EquipoSalon>> equipos(int salonId) async {
    final lista = await _api.getTodo('/recursos', parametros: {'salon_id': salonId});
    return [
      for (final e in lista.cast<Map<String, dynamic>>())
        EquipoSalon(
          id: (e['id'] as num).toInt(),
          categoria: (e['categoria'] ?? 'otro').toString(),
          serial: (e['serial'] ?? '').toString(),
          estado: EstadoEquipo.desde(e['estado']?.toString()),
          descripcion: e['descripcion'] as String?,
        ),
    ];
  }

  @override
  Future<ResultadoEstadoEquipo> cambiarEstadoEquipo(int equipoId, EstadoEquipo estado,
      {String? nota, int? reporteSalonId}) async {
    final r = await _api.patch('/recursos/$equipoId/estado', cuerpo: {
      'estado': estado.api,
      if ((nota ?? '').trim().isNotEmpty) 'nota': nota!.trim(),
      if (reporteSalonId != null) 'reporte_salon_id': reporteSalonId,
    }) as Map<String, dynamic>;
    return ResultadoEstadoEquipo(
      sugerirReporte: r['sugerir_reporte'] as bool? ?? false,
      reportesAbiertos: [
        for (final x in (r['reportes_equipo_abiertos'] as List? ?? const [])
            .cast<Map<String, dynamic>>())
          ReporteEquipoAbierto(
              id: (x['id'] as num).toInt(), descripcion: (x['descripcion'] ?? '').toString()),
      ],
    );
  }

  @override
  Future<void> agregarEquipo(int salonId, String categoria, String serial) => _api.post(
        '/recursos',
        cuerpo: {'categoria': categoria, 'salon_id': salonId, 'serial': serial.trim()},
      );

  @override
  Future<void> retirarEquipo(int equipoId) => _api.delete('/recursos/$equipoId');

  @override
  Future<List<PlantillaPorSalon>> plantilla(String plantilla, List<int> salonIds,
      {int? computadores, required bool aplicar}) async {
    final lista = await _api.post(
      aplicar ? '/recursos/plantillas/aplicar' : '/recursos/plantillas/vista-previa',
      cuerpo: {
        'plantilla': plantilla,
        'salon_ids': salonIds,
        if (computadores != null) 'computadores': computadores,
      },
    ) as List<dynamic>;
    return [
      for (final p in lista.cast<Map<String, dynamic>>())
        PlantillaPorSalon(
          salonNombre: (p['salon_nombre'] ?? '').toString(),
          agregar: {
            for (final e in (p['agregar'] as Map<String, dynamic>? ?? const {}).entries)
              e.key: (e.value as num).toInt(),
          },
        ),
    ];
  }

  @override
  Future<VistaPreviaLote> lote(String edificio, int? piso, DatosHabilitacion datos,
      {required bool aplicar}) async {
    final r = await _api.post(
      aplicar ? '/salones/habilitacion/lote' : '/salones/habilitacion/lote/vista-previa',
      cuerpo: {'edificio': edificio, if (piso != null) 'piso': piso, ..._habilitacion(datos)},
    ) as Map<String, dynamic>;
    return VistaPreviaLote(
      salones: _textos(r['salones']),
      sinCambio: _textos(r['sin_cambio']),
      solicitudesAfectadas: (r['solicitudes_afectadas'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<List<ResumenPiso>> resumen() async {
    final lista = await _api.get('/salones/ocupacion/resumen') as List<dynamic>;
    return [
      for (final e in lista.cast<Map<String, dynamic>>())
        ResumenPiso(
          edificio: (e['edificio'] ?? '').toString(),
          piso: (e['piso'] as num?)?.toInt(),
          total: (e['total'] as num).toInt(),
          libres: (e['libres'] as num).toInt(),
          ocupados: (e['ocupados'] as num).toInt(),
          deshabilitados: (e['deshabilitados'] as num).toInt(),
        ),
    ];
  }

  @override
  Future<String> exportarCsv() => _api.getTexto('/salones/exportar.csv');
}
