/// Usuario del sistema (ubicuo: "Usuario" con rol administrador o usuario_utb).
class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  final int id;
  final String nombre;
  final String email;
  final String rol;

  /// Auxiliar de planta / laboratorio. El backend define "administrador" o "usuario_utb"
  /// (comentario de `Usuario.rol`); se toleran variantes por si cambia el texto.
  bool get esAdministrador {
    final r = rol.trim().toLowerCase();
    return r == 'administrador' || r == 'admin' || r == 'auxiliar';
  }

  String get rolLegible => esAdministrador ? 'Auxiliar de planta' : 'Usuario UTB';
}

class Sesion {
  const Sesion({required this.token, required this.usuario});
  final String token;
  final Usuario usuario;
}

abstract class AuthRepository {
  /// POST /auth/login. Si [conocido] viene (p. ej. justo después de registrarse) no hace falta
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
    required String rol,
    required String password,
  });

  /// GET /auth/me (perfil del usuario autenticado)
  Future<Usuario> usuarioActual();

  /// GET /auth/user/{id}
  Future<Usuario> obtenerUsuario(int id);

  /// GET /salud (health check profundo, S8)
  Future<bool> servidorSaludable();
}
