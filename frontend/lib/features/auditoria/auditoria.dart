/// Bitácora de auditoría (ADR-0010 de auditoría): quién hizo qué y cuándo. Solo lectura y solo
/// para el administrador. Dominio, datos y estado en un archivo porque el módulo es pequeño.
library;

import 'package:flutter/foundation.dart';

import '../../core/error/api_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/state/carga.dart';
import '../../core/utils/utilidades.dart';

// ── Dominio ─────────────────────────────────────────────────────────────

class EventoAuditoria {
  const EventoAuditoria({
    required this.id,
    required this.ocurrioEn,
    required this.accion,
    required this.entidad,
    this.actorNombre,
    this.entidadId,
    this.detalle,
  });

  final int id;
  final DateTime ocurrioEn;
  final String accion;
  final String entidad;
  final String? actorNombre;
  final int? entidadId;
  final String? detalle;

  /// "salon.reporte.resolver" → "Salon · reporte · resolver"
  String get accionLegible {
    final t = accion.replaceAll('_', ' ').split('.').join(' · ');
    return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
  }
}

abstract class AuditoriaRepository {
  /// GET /auditoria?entidad=&accion=
  Future<List<EventoAuditoria>> listar({String? entidad, String? accion});

  /// GET /auditoria/exportar (CSV con los mismos filtros).
  Future<String> exportarCsv({String? entidad, String? accion});
}

// ── Datos ───────────────────────────────────────────────────────────────

class AuditoriaRepositoryImpl implements AuditoriaRepository {
  AuditoriaRepositoryImpl(this._api);
  final ApiClient _api;

  Map<String, dynamic> _filtros(String? entidad, String? accion) => {
        if (entidad != null) 'entidad': entidad,
        if (accion != null && accion.trim().isNotEmpty) 'accion': accion.trim(),
      };

  @override
  Future<String> exportarCsv({String? entidad, String? accion}) =>
      _api.getTexto('/auditoria/exportar', parametros: _filtros(entidad, accion));

  @override
  Future<List<EventoAuditoria>> listar({String? entidad, String? accion}) async {
    final cuerpo = await _api.get(
      '/auditoria',
      parametros: {'limit': 100, ..._filtros(entidad, accion)},
    ) as List<dynamic>;
    return cuerpo.map((e) {
      final j = e as Map<String, dynamic>;
      return EventoAuditoria(
        id: (j['id'] as num).toInt(),
        ocurrioEn: parsearFechaServidor(j['ocurrio_en'].toString()),
        accion: (j['accion'] ?? '').toString(),
        entidad: (j['entidad'] ?? '').toString(),
        actorNombre: j['actor_nombre'] as String?,
        entidadId: (j['entidad_id'] as num?)?.toInt(),
        detalle: j['detalle'] as String?,
      );
    }).toList();
  }
}

// ── Estado ──────────────────────────────────────────────────────────────

class AuditoriaController extends ChangeNotifier {
  AuditoriaController(this._repo);
  final AuditoriaRepository _repo;

  List<EventoAuditoria> _eventos = const [];
  Carga _carga = Carga.inicial;
  String? _error;
  String? _entidad;
  String? _accion;

  String? get accion => _accion;

  /// Filtra por acción exacta o prefijo ("usuario.rol", "salon").
  Future<void> fijarAccion(String? accion) {
    _accion = (accion?.trim().isEmpty ?? true) ? null : accion!.trim();
    return cargar();
  }

  /// CSV de lo filtrado (máx. 5000 filas en el servidor).
  Future<String> exportarCsv() => _repo.exportarCsv(entidad: _entidad, accion: _accion);

  Carga get carga => _carga;
  String? get error => _error;
  List<EventoAuditoria> get eventos => _eventos;
  String? get entidad => _entidad;

  /// Entidades presentes, para los filtros.
  static const entidades = {
    'salon': 'Salones',
    'prestamo_salon': 'Solicitudes',
    'reporte_salon': 'Reportes',
    'recurso': 'Equipos',
    'mantenimiento': 'Mantenimiento',
    'horario': 'Horarios',
    'usuario': 'Usuarios',
  };

  Future<void> cargar({String? entidad, bool cambiarFiltro = false}) async {
    if (cambiarFiltro) _entidad = entidad;
    _carga = Carga.cargando;
    _error = null;
    notifyListeners();
    try {
      _eventos = await _repo.listar(entidad: _entidad, accion: _accion);
      _carga = Carga.ok;
    } on ApiException catch (e) {
      _carga = Carga.error;
      _error = e.mensaje;
    }
    notifyListeners();
  }
}
