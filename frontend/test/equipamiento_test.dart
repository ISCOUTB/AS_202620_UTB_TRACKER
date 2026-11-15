import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utb_tracker_app/core/theme/app_theme.dart';
import 'package:utb_tracker_app/features/salones/data/salones_data.dart';
import 'package:utb_tracker_app/features/salones/domain/entities/salon.dart';
import 'package:utb_tracker_app/features/salones_admin/data/salones_admin_data.dart';
import 'package:utb_tracker_app/features/salones_admin/domain/entities/ocupacion.dart';
import 'package:utb_tracker_app/features/salones_admin/domain/repositories/salones_admin_repository.dart';
import 'package:utb_tracker_app/features/salones_admin/presentation/salones_admin_controller.dart';
import 'package:utb_tracker_app/shared/equipamiento_chips.dart';

Map<String, dynamic> _salon(int id, String nombre,
        {String tipo = 'aula', List<Map<String, dynamic>> equipos = const []}) =>
    {
      'id': id,
      'nombre': nombre,
      'ubicacion': 'Edificio A',
      'capacidad': 30,
      'estado': 'disponible',
      'tipo': tipo,
      'descripcion': 'Con tablero inteligente',
      'equipamiento': equipos,
    };

OcupacionSalon _ocupacion(Map<String, dynamic> salon) => OcupacionModel.desdeJson({
      'salon': salon,
      'ocupante': 'libre',
      'solicitudes_pendientes': 0,
      'reportes_abiertos': 0,
    });

class _RepoFalso extends Fake implements SalonesAdminRepository {
  _RepoFalso(this.items);
  final List<OcupacionSalon> items;

  @override
  Future<List<OcupacionSalon>> listarOcupacion() async => items;
}

void main() {
  test('parseo de tipo, descripción, equipamiento y sugerencia', () {
    final s = SalonModel.desdeJson({
      ..._salon(1, 'LAB-SIS2', equipos: [
        {'categoria': 'computador', 'total': 13, 'operativos': 12},
      ]),
      'tipo_sugerido': 'laboratorio_computo',
    });
    expect(s.tipo, TipoSalon.aula);
    expect(s.descripcion, 'Con tablero inteligente');
    expect(s.equipamiento.single.fueraDeServicio, 1);
    expect(s.operativos('computador'), 12);
    expect(s.tipoSugerido, TipoSalon.laboratorioComputo);
  });

  test('un servidor viejo sin los campos nuevos no rompe el parseo', () {
    final s = SalonModel.desdeJson(
        {'id': 1, 'nombre': 'A', 'ubicacion': 'B', 'capacidad': 10, 'estado': 'disponible'});
    expect(s.tipo, TipoSalon.aula);
    expect(s.equipamiento, isEmpty);
    expect(s.tipoSugerido, isNull);
    expect(TipoSalon.desdeApi('inventado'), TipoSalon.aula);
  });

  testWidgets('EquipamientoChips: cantidad y "dañado" en texto, no solo en color', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.oscuro,
      home: const Scaffold(
        body: EquipamientoChips(equipamiento: [
          EquipoCategoria(categoria: 'computador', total: 20, operativos: 18),
          EquipoCategoria(categoria: 'video_beam', total: 1, operativos: 0),
          EquipoCategoria(categoria: 'aire_ac', total: 1, operativos: 1),
        ]),
      ),
    ));
    expect(find.text('20 Computadores · 2 dañados'), findsOneWidget);
    expect(find.text('1 Video beam · 1 dañado'), findsOneWidget);
    expect(find.text('1 Aire'), findsOneWidget);
    expect(find.bySemanticsLabel('Video beam: 1, 1 dañado'), findsOneWidget);
  });

  testWidgets('EquipamientoChips vacío y compacto', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.oscuro,
      home: const Scaffold(
        body: Column(children: [
          EquipamientoChips(equipamiento: []),
          EquipamientoChips(
              equipamiento: [EquipoCategoria(categoria: 'tv', total: 2, operativos: 2)],
              compacto: true),
        ]),
      ),
    ));
    expect(find.text('Sin equipos registrados'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  test('filtros del panel por tipo y por equipo operativo', () async {
    final c = SalonesAdminController(_RepoFalso([
      _ocupacion(_salon(1, 'LAB-1', tipo: 'laboratorio_computo', equipos: [
        {'categoria': 'computador', 'total': 20, 'operativos': 20},
      ])),
      _ocupacion(_salon(2, 'A1-101', equipos: [
        {'categoria': 'video_beam', 'total': 1, 'operativos': 1},
      ])),
      _ocupacion(_salon(3, 'A1-102', equipos: [
        {'categoria': 'video_beam', 'total': 1, 'operativos': 0}, // dañado: no cuenta
      ])),
    ]));
    await c.cargar();

    c.fijarTipo(TipoSalon.laboratorioComputo);
    expect(c.visibles.map((o) => o.salon.nombre), ['LAB-1']);

    c.fijarTipo(null);
    c.fijarConEquipo('video_beam');
    expect(c.visibles.map((o) => o.salon.nombre), ['A1-101']);

    c.fijarConEquipo(null);
    c.fijarBusqueda('tablero');
    expect(c.visibles.length, 3);
  });
}
