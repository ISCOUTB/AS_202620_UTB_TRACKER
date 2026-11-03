import 'package:flutter/foundation.dart';

import '../../../core/error/api_exception.dart';
import '../data/mantenimiento_data.dart';

class MantenimientoController extends ChangeNotifier {
  MantenimientoController(this._remote);
  final MantenimientoRemoteDataSource _remote;

  List<MantenimientoItem> _items = const [];
  bool _cargando = false;
  String? _error;

  List<MantenimientoItem> get items => _items;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _remote.listar();
    } on ApiException catch (error) {
      _error = error.mensaje;
    } catch (_) {
      _error = 'No se pudieron cargar las órdenes de mantenimiento';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<String?> actualizar(int id, String estado) async {
    try {
      final actualizado = await _remote.actualizar(id, estado);
      _items = [
        for (final item in _items)
          if (item.id == id) actualizado else item,
      ];
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.mensaje;
    } catch (_) {
      return 'No se pudo actualizar la orden';
    }
  }
}
