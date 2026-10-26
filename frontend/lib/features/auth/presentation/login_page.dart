import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/assets/figuras.dart';
import '../../../core/config/api_config.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/uber_widgets.dart';
import 'auth_controller.dart';

enum _Modo { ingresar, registrar }

/// Pantalla de acceso única: "Iniciar sesión" y "Crear cuenta" comparten pantalla y
/// se alternan con un selector, sin cambiar de ruta (el estado y el teclado se conservan).
/// Cuando hay sesión, la raíz de la app (`app.dart`) cambia sola a la pantalla principal.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final AuthController _auth = sl<AuthController>();

  _Modo _modo = _Modo.ingresar;
  bool _ocultar = true;

  bool get _registrando => _modo == _Modo.registrar;

  @override
  void initState() {
    super.initState();
    _auth.comprobarServidor();
    // Para que el medidor de contraseña se actualice al teclear.
    _password.addListener(() {
      if (_registrando) setState(() {});
    });
  }

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _cambiarModo(_Modo m) {
    if (m == _modo) return;
    _auth.limpiarError();
    setState(() => _modo = m);
  }

  Future<void> _continuar() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    if (_registrando) {
      await _auth.registrar(
        nombre: _nombre.text,
        email: _email.text,
        password: _password.text,
      );
    } else {
      await _auth.iniciarSesion(_nombre.text, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _auth,
          builder: (context, _) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _form,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Marca(servidorOk: _auth.servidorOk, onTap: _auth.comprobarServidor),
                        const SizedBox(height: 36),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Column(
                            key: ValueKey(_modo),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _registrando ? 'Crea tu cuenta' : 'Bienvenido de vuelta',
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _registrando
                                    ? 'Solicita salones y consulta equipos de la UTB en segundos.'
                                    : 'Ingresa para ver el estado de los salones y equipos del campus.',
                                style: const TextStyle(
                                  color: AppColors.textoSuave,
                                  fontSize: 16,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),
                        _Selector(modo: _modo, onCambio: _cambiarModo),
                        const SizedBox(height: 22),
                        _CampoUber(
                          controller: _nombre,
                          etiqueta: 'Nombre de usuario',
                          icono: Icons.person_outline_rounded,
                          autofill: const [AutofillHints.username],
                          accion: TextInputAction.next,
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.isEmpty) return 'Escribe tu nombre de usuario';
                            if (_registrando && t.length < 3) return 'Mínimo 3 caracteres';
                            return null;
                          },
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          alignment: Alignment.topCenter,
                          child: _registrando
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: _CampoUber(
                                    controller: _email,
                                    etiqueta: 'Correo institucional',
                                    icono: Icons.mail_outline_rounded,
                                    teclado: TextInputType.emailAddress,
                                    autofill: const [AutofillHints.email],
                                    accion: TextInputAction.next,
                                    validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                            .hasMatch((v ?? '').trim())
                                        ? null
                                        : 'Escribe un correo válido',
                                  ),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                        const SizedBox(height: 12),
                        _CampoUber(
                          controller: _password,
                          etiqueta: 'Contraseña',
                          icono: Icons.lock_outline_rounded,
                          oculto: _ocultar,
                          autofill: [
                            _registrando ? AutofillHints.newPassword : AutofillHints.password,
                          ],
                          accion: TextInputAction.done,
                          onEnviar: (_) => _continuar(),
                          sufijo: IconButton(
                            tooltip: _ocultar ? 'Mostrar contraseña' : 'Ocultar contraseña',
                            icon: Icon(
                              _ocultar ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                              color: AppColors.textoSuave,
                            ),
                            onPressed: () => setState(() => _ocultar = !_ocultar),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Escribe tu contraseña';
                            if (_registrando && v.length < 8) return 'Mínimo 8 caracteres';
                            return null;
                          },
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          alignment: Alignment.topCenter,
                          child: _registrando
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: _MedidorClave(clave: _password.text),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                        if (_auth.error != null) ...[
                          const SizedBox(height: 16),
                          _CajaError(_auth.error!),
                        ],
                        const SizedBox(height: 24),
                        BotonPildora(
                          texto: _registrando ? 'Crear cuenta' : 'Continuar',
                          icono: Icons.arrow_forward_rounded,
                          cargando: _auth.cargando,
                          onPressed: _continuar,
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: TextButton(
                            onPressed: _auth.cargando
                                ? null
                                : () => _cambiarModo(_registrando ? _Modo.ingresar : _Modo.registrar),
                            child: Text(
                              _registrando
                                  ? '¿Ya tienes cuenta? Inicia sesión'
                                  : '¿Eres nuevo? Crea tu cuenta',
                              style: const TextStyle(
                                color: AppColors.textoSuave,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Logo, nombre y un punto discreto que indica si el servidor responde.
class _Marca extends StatelessWidget {
  const _Marca({required this.servidorOk, required this.onTap});
  final bool? servidorOk;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = servidorOk == null
        ? AppColors.neutro
        : servidorOk!
            ? AppColors.disponible
            : AppColors.danado;
    final texto = servidorOk == null
        ? 'Comprobando…'
        : servidorOk!
            ? 'Conectado'
            : 'Sin conexión';
    return Row(
      children: [
        SvgPicture.asset(Figuras.logo, height: 40),
        const SizedBox(width: 12),
        const Text('UTB Tracker', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const Spacer(),
        Tooltip(
          message: 'Servidor: ${ApiConfig.baseUrl}\nToca para volver a comprobar',
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.superficie,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    texto,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textoSuave),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Interruptor de dos opciones en forma de píldora (Iniciar sesión / Crear cuenta).
class _Selector extends StatelessWidget {
  const _Selector({required this.modo, required this.onCambio});
  final _Modo modo;
  final ValueChanged<_Modo> onCambio;

  @override
  Widget build(BuildContext context) {
    Widget opcion(_Modo m, String texto) {
      final activo = modo == m;
      return Expanded(
        child: Semantics(
          button: true,
          selected: activo,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onCambio(m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: activo ? AppColors.texto : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                texto,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: activo ? Colors.black : AppColors.textoSuave,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.superficieAlta,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          opcion(_Modo.ingresar, 'Iniciar sesión'),
          opcion(_Modo.registrar, 'Crear cuenta'),
        ],
      ),
    );
  }
}

/// Campo de texto relleno, sin borde, con icono: el aspecto de los formularios de Uber.
class _CampoUber extends StatelessWidget {
  const _CampoUber({
    required this.controller,
    required this.etiqueta,
    required this.icono,
    required this.validator,
    this.oculto = false,
    this.sufijo,
    this.teclado,
    this.autofill,
    this.accion,
    this.onEnviar,
  });

  final TextEditingController controller;
  final String etiqueta;
  final IconData icono;
  final String? Function(String?) validator;
  final bool oculto;
  final Widget? sufijo;
  final TextInputType? teclado;
  final Iterable<String>? autofill;
  final TextInputAction? accion;
  final ValueChanged<String>? onEnviar;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder borde(Color c, [double w = 0]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: w == 0 ? BorderSide.none : BorderSide(color: c, width: w),
        );

    return TextFormField(
      controller: controller,
      obscureText: oculto,
      keyboardType: teclado,
      textInputAction: accion,
      autofillHints: autofill,
      onFieldSubmitted: onEnviar,
      validator: validator,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono, color: AppColors.textoSuave),
        suffixIcon: sufijo,
        filled: true,
        fillColor: AppColors.superficieAlta,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: borde(Colors.transparent),
        enabledBorder: borde(Colors.transparent),
        focusedBorder: borde(AppColors.texto, 1.5),
        errorBorder: borde(AppColors.danado, 1.2),
        focusedErrorBorder: borde(AppColors.danado, 1.5),
      ),
    );
  }
}

/// Tres barras que se llenan según la fuerza de la contraseña (solo informativo).
class _MedidorClave extends StatelessWidget {
  const _MedidorClave({required this.clave});
  final String clave;

  static int fuerza(String c) {
    if (c.isEmpty) return 0;
    var puntos = 0;
    if (c.length >= 8) puntos++;
    if (RegExp(r'[A-Za-z]').hasMatch(c) && RegExp(r'\d').hasMatch(c)) puntos++;
    if (c.length >= 12 || RegExp(r'[^A-Za-z0-9]').hasMatch(c)) puntos++;
    return puntos;
  }

  @override
  Widget build(BuildContext context) {
    final nivel = fuerza(clave);
    final color = switch (nivel) {
      0 || 1 => AppColors.danado,
      2 => AppColors.prestado,
      _ => AppColors.disponible,
    };
    final texto = switch (nivel) {
      0 => 'Usa al menos 8 caracteres',
      1 => 'Contraseña débil',
      2 => 'Contraseña aceptable',
      _ => 'Contraseña fuerte',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 3; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 5,
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: i < nivel ? color : AppColors.superficieAlta,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(texto, style: const TextStyle(fontSize: 12.5, color: AppColors.textoSuave)),
      ],
    );
  }
}

class _CajaError extends StatelessWidget {
  const _CajaError(this.mensaje);
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.danado.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.danado.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danado, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(mensaje, style: const TextStyle(fontSize: 14))),
          ],
        ),
      ),
    );
  }
}
