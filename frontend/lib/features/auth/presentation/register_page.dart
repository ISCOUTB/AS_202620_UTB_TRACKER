import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import 'auth_controller.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final AuthController _auth = sl<AuthController>();

  /// Valores que acepta el backend (comentario de `Usuario.rol`).
  String _rol = 'usuario_utb';

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await _auth.registrar(
      nombre: _nombre.text,
      email: _email.text,
      rol: _rol,
      password: _password.text,
    );
    if (ok && mounted) {
      // Ya hay sesión: se vuelve a la raíz, que mostrará la pantalla principal.
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _auth,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nombre,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Nombre de usuario'),
                      validator: (v) => (v == null || v.trim().length < 3)
                          ? 'Mínimo 3 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Correo'),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        return (t.contains('@') && t.contains('.'))
                            ? null
                            : 'Escribe un correo válido';
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        helperText: 'Mínimo 8 caracteres',
                      ),
                      validator: (v) =>
                          (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null,
                    ),
                    if (ApiConfig.permitirElegirRol) ...[
                      const SizedBox(height: 18),
                      const Text('Rol', style: TextStyle(color: AppColors.textoSuave)),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 'usuario_utb', label: Text('Usuario UTB')),
                          ButtonSegment(value: 'administrador', label: Text('Auxiliar')),
                        ],
                        selected: {_rol},
                        onSelectionChanged: (s) => setState(() => _rol = s.first),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'En producción el rol de auxiliar debe asignarlo un administrador.',
                        style: TextStyle(color: AppColors.textoTenue, fontSize: 12),
                      ),
                    ],
                    if (_auth.error != null) ...[
                      const SizedBox(height: 16),
                      Text(_auth.error!, style: const TextStyle(color: AppColors.danado)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _auth.cargando ? null : _crear,
                      child: _auth.cargando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.black,
                              ),
                            )
                          : const Text('Crear cuenta y entrar'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
