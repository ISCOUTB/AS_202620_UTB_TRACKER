import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/politica.dart';
import '../../../shared/uber_widgets.dart';
import 'auth_controller.dart';

/// Pide el correo nuevo y la contraseña actual. El correo NO cambia hasta abrir el enlace que
/// llega al correo nuevo; al anterior se le avisa (ADR-0014).
Future<void> mostrarCambiarCorreo(BuildContext context) async {
  final auth = sl<AuthController>();
  final form = GlobalKey<FormState>();
  final correo = TextEditingController();
  final clave = TextEditingController();
  final enviado = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
      child: ListenableBuilder(
        listenable: auth,
        builder: (ctx, _) => Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Cambiar correo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text(
                'Te enviaremos un enlace al correo nuevo. Hasta que lo abras, tu cuenta sigue '
                'usando el actual.',
                style: TextStyle(color: AppColors.textoSuave, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: correo,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Correo nuevo'),
                validator: (v) =>
                    Politica.correoValido(v ?? '') ? null : Politica.msgCorreoInvalido,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: clave,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Tu contraseña actual'),
                validator: (v) => (v ?? '').isEmpty ? 'Escribe tu contraseña actual' : null,
              ),
              if (auth.error != null) ...[
                const SizedBox(height: 10),
                Text(auth.error!, style: const TextStyle(color: AppColors.danado)),
              ],
              const SizedBox(height: 14),
              BotonPildora(
                texto: 'Enviar enlace',
                icono: Icons.send_rounded,
                cargando: auth.cargando,
                onPressed: () async {
                  if (!form.currentState!.validate()) return;
                  final ok = await auth.solicitarCambioCorreo(correo.text, clave.text);
                  if (ok && ctx.mounted) Navigator.pop(ctx, true);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
  correo.dispose();
  clave.dispose();
  auth.limpiarError();
  if (enviado == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Revisa el correo nuevo y abre el enlace para confirmar el cambio.'),
    ));
  }
}
