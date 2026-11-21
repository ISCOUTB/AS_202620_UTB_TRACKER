import 'permisos.dart';
import 'preferencias.dart';

export 'permisos.dart';
export 'preferencias.dart';

/// Usuario del sistema. `rol` es el valor guardado (usuario_utb | auxiliar | administrador);
/// lo que puede hacer está en [permisos] (ADR-0018).
class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.nombreMostrar,
    this.telefono,
    this.dependencia,
    this.colorAvatar,
    this.preferencias = const Preferencias(),
    String? rolEtiqueta,
    Permisos? permisos,
    this.correoInstitucional = true,
    this.rolOrigen = 'base',
    this.rolOrigenTexto,
    this.cargo,
    this.tieneFoto = false,
    this.fotoVersion = 0,
  })  : _rolEtiqueta = rolEtiqueta,
        _permisos = permisos;

  final int id;
  final String nombre;
  final String email;
  final String rol;

  /// Sin verificar puede entrar y consultar, pero no solicitar salones (ADR-0014).

  /// Perfil personalizable (ADR-0016).
  final String? nombreMostrar;
  final String? telefono;
  final String? dependencia;

  /// "#RRGGBB" elegido para el avatar, o null (color de la marca).
  final String? colorAvatar;
  final Preferencias preferencias;

  /// Lo que se muestra como nombre: el nombre para mostrar si existe, si no el de usuario.
  String get nombreVisible =>
      (nombreMostrar?.trim().isNotEmpty ?? false) ? nombreMostrar!.trim() : nombre;

  final String? _rolEtiqueta;
  final Permisos? _permisos;

  /// Etiqueta del rol (la manda el servidor).
  String get rolEtiqueta =>
      (_rolEtiqueta?.isNotEmpty ?? false) ? _rolEtiqueta! : 'Sin rol';

  /// Permisos REALES (los que aplica el servidor).
  Permisos get permisos => _permisos ?? Permisos.ninguno;

  /// False en cuentas antiguas con correo no institucional: el perfil avisa (ADR-0019).
  final bool correoInstitucional;

  /// De dónde sale el rol (solo lectura): "base", "manual" (lo puso un administrador). [rolOrigenTexto] lo explica en español.
  final String rolOrigen;
  final String? rolOrigenTexto;

  /// Cargo o dependencia que viene de la asignación (no editable en el perfil).
  final String? cargo;

  /// Foto de perfil (ADR-0020). [fotoVersion] cambia con cada subida: sirve de clave de caché.
  final bool tieneFoto;
  final int fotoVersion;

  /// Copia con la foto actualizada sin volver a pedir el perfil.
  Usuario conFoto({required bool tiene, required int version}) => Usuario(
        id: id,
        nombre: nombre,
        email: email,
        rol: rol,
        nombreMostrar: nombreMostrar,
        telefono: telefono,
        dependencia: dependencia,
        colorAvatar: colorAvatar,
        preferencias: preferencias,
        rolEtiqueta: _rolEtiqueta,
        permisos: _permisos,
        correoInstitucional: correoInstitucional,
        rolOrigen: rolOrigen,
        rolOrigenTexto: rolOrigenTexto,
        cargo: cargo,
        tieneFoto: tiene,
        fotoVersion: version,
      );
}

class Sesion {
  const Sesion({required this.token, required this.usuario, this.refreshToken});
  final String token;

  /// Permite renovar el access token sin volver a pedir la contraseña (ADR-0014).
  final String? refreshToken;
  final Usuario usuario;
}

abstract class AuthRepository {
  /// POST /auth/login con nombre de usuario O correo. Si [conocido] viene (p. ej. justo después de registrarse) no hace falta
  /// averiguar quién es el usuario.
  Future<Sesion> iniciarSesion(
    String nombre,
    String password, {
    Usuario? conocido,
  });

  /// POST /auth/register
  Future<Usuario> registrar({
    required String nombre,
    required String email,
    required String password,
  });

  /// GET /auth/me (perfil del usuario autenticado)
  Future<Usuario> usuarioActual();

  /// GET /auth/user/{id}
  Future<Usuario> obtenerUsuario(int id);

  /// GET /auth/users (Panel administrativo — listar usuarios para gestión)
  Future<List<Usuario>> listarUsuarios({String? busqueda, String? rol});

  /// PATCH /auth/user/{id}/role (Panel administrativo — asignar o modificar rol)
  Future<Usuario> actualizarRolUsuario(int usuarioId, String nuevoRol);

  /// PATCH /auth/fcm-token
  Future<void> registrarTokenFcm(String token);

  /// GET /salud (health check profundo, S8)
  Future<bool> servidorSaludable();

}
