/// Regla del código de salón de la UTB (ADR-0021). ESPEJO de `app/service/catalogo.py`:
/// si cambia allá, cambia aquí (el servidor valida siempre; esto es para avisar antes).
///
///   A + edificio (1 dígito) + "-" + piso (1 dígito) + salón (2 dígitos)
///   A1-101 = edificio A1, piso 1, salón 01.
library;

final _patron = RegExp(r'^A(\d)-(\d)(\d{2})$');
final _pareceCodigo = RegExp(r'^A\d');

String normalizarCodigo(String nombre) => nombre.replaceAll(RegExp(r'\s'), '').toUpperCase();

/// ¿El nombre debe seguir la regla? Los que no empiezan por A + dígito son espacios especiales.
bool esCodigoDeCatalogo(String nombre) => _pareceCodigo.hasMatch(normalizarCodigo(nombre));

/// Partes de un código válido, o null.
({String edificio, int piso, int numero})? partesCodigo(String nombre) {
  final m = _patron.firstMatch(normalizarCodigo(nombre));
  if (m == null) return null;
  return (edificio: 'A${m.group(1)}', piso: int.parse(m.group(2)!), numero: int.parse(m.group(3)!));
}

String ubicacionDe(String edificio, int piso) => 'Edificio $edificio, piso $piso';

/// Primer problema en español, o null si el código es válido.
String? errorCodigo(String nombre) {
  final p = partesCodigo(nombre);
  if (p == null) {
    return 'Usa la forma A1-101: A, edificio (1 dígito), guion, piso (1 dígito) y salón '
        '(2 dígitos).';
  }
  if (p.numero == 0) return 'El número de salón no puede ser 00.';
  return null;
}

/// Códigos de un rango: (2, 5, 1, 3) -> A2-501, A2-502, A2-503.
List<String> codigosDeRango(int edificio, int piso, int desde, int hasta) => [
      for (var n = desde; n <= hasta; n++) 'A$edificio-$piso${n.toString().padLeft(2, '0')}',
    ];

/// Orden natural: A1-101, A1-102 … A1-201 … A2-201; los espacios especiales al final.
int compararCodigos(String a, String b) {
  final pa = partesCodigo(a), pb = partesCodigo(b);
  if (pa != null && pb != null) {
    return [pa.edificio.compareTo(pb.edificio), pa.piso - pb.piso, pa.numero - pb.numero]
        .firstWhere((c) => c != 0, orElse: () => 0);
  }
  if (pa != null) return -1;
  if (pb != null) return 1;
  return a.toLowerCase().compareTo(b.toLowerCase());
}

/// Qué crearía un rango (POST /salones/catalogo/rango/vista-previa) o qué creó.
class VistaPreviaRango {
  const VistaPreviaRango({
    required this.edificio,
    required this.piso,
    required this.nuevos,
    required this.existentes,
    this.creados = const [],
  });

  final String edificio;
  final int piso;
  final List<String> nuevos;
  final List<String> existentes;
  final List<String> creados;
}

/// Salón que no sigue la regla o no está en el catálogo (GET /salones/catalogo/fuera).
class SalonFueraCatalogo {
  const SalonFueraCatalogo({
    required this.id,
    required this.nombre,
    required this.tieneHistorial,
    required this.problema,
    required this.propuesta,
  });

  final int id;
  final String nombre;
  final bool tieneHistorial;
  final String problema;
  final String propuesta;
}

/// Contrato del catálogo (solo Administrador). La UI no sabe de HTTP.
abstract class CatalogoRepository {
  Future<VistaPreviaRango> vistaPrevia(int edificio, int piso, int desde, int hasta);
  Future<VistaPreviaRango> crearRango(int edificio, int piso, int desde, int hasta,
      {int? capacidad});
  Future<List<SalonFueraCatalogo>> fueraDelCatalogo();
  Future<void> desactivar(int salonId);
}
