import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/assets/figuras.dart';
import '../../../core/config/api_config.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import 'auth_controller.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _password = TextEditingController();
  final AuthController _auth = sl<AuthController>();
  bool _ocultar = true;

  @override
  void initState() {
    super.initState();
    _auth.comprobarServidor();
  }

  @override
  void dispose() {
    _nombre.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await _auth.iniciarSesion(_nombre.text, _password.text);
    // Si salió bien, la raíz de la app cambia sola a la pantalla principal.
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: SvgPicture.asset(Figuras.logo, height: 84)),
                        const SizedBox(height: 20),
                        const Text(
                          'UTB Tracker',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Préstamo y estado de equipos de salones y laboratorios',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textoSuave),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _nombre,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          decoration: const InputDecoration(labelText: 'Nombre de usuario'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Escribe tu nombre de usuario'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _ocultar,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _entrar(),
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            suffixIcon: IconButton(
                              icon: Icon(_ocultar ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _ocultar = !_ocultar),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Escribe tu contraseña' : null,
                        ),
                        if (_auth.error != null) ...[
                          const SizedBox(height: 14),
                          _CajaError(_auth.error!),
                        ],
                        const SizedBox(height: 22),
                        FilledButton(
                          onPressed: _auth.cargando ? null : _entrar,
                          child: _auth.cargando
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text('Iniciar sesión'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _auth.cargando
                              ? null
                              : () {
                                  _auth.limpiarError();
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const RegisterPage(),
                                    ),
                                  );
                                },
                          child: const Text('Crear cuenta'),
                        ),
                        const SizedBox(height: 28),
                        _EstadoServidor(ok: _auth.servidorOk, onTap: _auth.comprobarServidor),
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

class _CajaError extends StatelessWidget {
  const _CajaError(this.mensaje);
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danado.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danado.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danado, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(mensaje, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

/// Muestra a qué servidor apunta la app y si /salud responde (útil al conectar emulador ↔ backend).
class _EstadoServidor extends StatelessWidget {
  const _EstadoServidor({required this.ok, required this.onTap});
  final bool? ok;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = ok == null
        ? AppColors.neutro
        : ok!
            ? AppColors.disponible
            : AppColors.danado;
    final texto = ok == null
        ? 'Comprobando servidor…'
        : ok!
            ? 'Servidor conectado'
            : 'Sin respuesta del servidor';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(texto, style: const TextStyle(color: AppColors.textoSuave)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              ApiConfig.baseUrl,
              style: const TextStyle(color: AppColors.textoTenue, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
