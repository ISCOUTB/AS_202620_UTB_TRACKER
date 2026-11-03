import 'package:flutter/foundation.dart';

import '../../../core/error/api_exception.dart';
import '../data/stats_data.dart';

class StatsController extends ChangeNotifier {
  StatsController(this._remote);
  final StatsRemoteDataSource _remote;

  DashboardStats? _stats;
  bool _cargando = false;
  String? _error;

  DashboardStats? get stats => _stats;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar({bool silencioso = false}) async {
    if (!silencioso) {
      _cargando = true;
      _error = null;
      notifyListeners();
    }
    try {
      _stats = await _remote.resumen();
      _error = null;
    } on ApiException catch (e) {
      if (!silencioso || _stats == null) {
        _error = e.mensaje;
      }
    } catch (_) {
      if (!silencioso || _stats == null) {
        _error = 'No se pudieron cargar los indicadores';
      }
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
