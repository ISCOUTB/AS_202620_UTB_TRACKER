import 'package:flutter/foundation.dart';

import '../../../core/error/api_exception.dart';
import '../../../core/state/carga.dart';
import '../domain/entities/ocupacion.dart';
import '../domain/repositories/salones_admin_repository.dart';

enum FiltroPanel {
  todos('Todos'),
  atencion('Por atender'),
  clases('En clase'),
  prestados('Prestados'),
  libres('Libres');

  const FiltroPanel(this.etiqueta);
  final String etiqueta;
}

/// Estado del panel del auxiliar: el plano de salones con su situación en vivo.
class SalonesAdminController extends ChangeNotifier {
  SalonesAdminController(this._repo);

  final SalonesAdminRepository _repo;

  List<OcupacionSalon> _items = const [];
  Carga _carga = Carga.inicial;
  String? _error;
  FiltroPanel _filtro = FiltroPanel.todos;
  String _busqueda = '';

  Carga get carga => _carga;
  String? get error => _error;
  List<OcupacionSalon> get todos => _items;
  FiltroPanel get filtro => _filtro;
  String get busqueda => _busqueda;

  void fijarFiltro(FiltroPanel f) {
    _filtro = f;
    notifyListeners();
  }

  void fijarBusqueda(String q) {
    _busqueda = q.trim();
    notifyListeners();
  }

  bool _coincide(OcupacionSalon o) {
    switch (_filtro) {
      case FiltroPanel.todos:
        return true;
      case FiltroPanel.atencion:
        return o.requiereAtencion;
      case FiltroPanel.clases:
        return o.ocupante == Ocupante.clase;
      case FiltroPanel.prestados:
        return o.ocupante == Ocupante.prestamo;
      case FiltroPanel.libres:
        return o.situacion == SituacionSalon.libre;
    }
  }

  /// Salones que cumplen filtro y búsqueda; los que necesitan atención van primero.
  List<OcupacionSalon> get visibles {
    final q = _busqueda.toLowerCase();
    final lista = _items.where((o) {
      if (!_coincide(o)) return false;
      if (q.isEmpty) return true;
      final texto =
          '${o.salon.nombre} ${o.salon.ubicacion} ${o.titular} ${o.subtitular}'.toLowerCase();
      return texto.contains(q);
    }).toList();
    lista.sort((a, b) {
      if (a.requiereAtencion != b.requiereAtencion) return a.requiereAtencion ? -1 : 1;
      return a.salon.nombre.compareTo(b.salon.nombre);
    });
    return lista;
  }

  int contar(FiltroPanel f) {
    final anterior = _filtro;
    _filtro = f;
    final n = _items.where(_coincide).length;
    _filtro = anterior;
    return n;
  }

  int get totalPendientes => _items.fold(0, (s, o) => s + o.solicitudesPendientes);
  int get totalReportes => _items.fold(0, (s, o) => s + o.reportesAbiertos);

  OcupacionSalon? porId(int id) {
    for (final o in _items) {
      if (o.salon.id == id) return o;
    }
    return null;
  }

  Future<void> cargar({bool silencioso = false}) async {
    if (!silencioso) {
      _carga = Carga.cargando;
      _error = null;
      notifyListeners();
    }
    try {
      _items = await _repo.listarOcupacion();
      _carga = Carga.ok;
      _error = null;
    } on ApiException catch (e) {
      if (!(silencioso && _items.isNotEmpty)) {
        _carga = Carga.error;
        _error = e.mensaje;
      }
    } catch (_) {
      if (!(silencioso && _items.isNotEmpty)) {
        _carga = Carga.error;
        _error = 'No se pudo cargar el estado de los salones';
      }
    }
    notifyListeners();
  }

  /// Confirma o desmiente la llegada del profesor. Devuelve un mensaje de error o null si salió bien.
  Future<String?> registrarPresencia(int salonId, {required bool presente, String? nota}) async {
    try {
      await _repo.registrarPresencia(salonId, presente: presente, nota: nota);
      await cargar(silencioso: true);
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    } catch (_) {
      return 'No se pudo registrar la presencia del profesor';
    }
  }
}
