import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/politica.dart';
import '../../../shared/uber_widgets.dart';
import 'auth_controller.dart';

/// Pide el correo institucional nuevo y la contraseña actual. Cambia al instante (ADR-0024) y al
/// correo anterior le llega un aviso.
Future<void> mostrarCambiarCorreo(BuildContext context) async {
  final auth = sl<AuthController>();
  final form = GlobalKey<FormState>();
  final correo = TextEditingController();
  final clave = TextEditingController();
  final cambiado = await showModalBottomSheet<bool>(
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
                'Solo se admite un correo institucional. Al correo actual le avisaremos del '
                'cambio.',
                style: TextStyle(color: AppColors.textoSuave, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: correo,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Correo institucional nuevo',
                  helperText: 'Ejemplo: ${Politica.ejemploCorreo}',
                ),
                validator: (v) => Politica.errorCorreoNuevo(v ?? ''),
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
                texto: 'Cambiar correo',
                icono: Icons.check_rounded,
                cargando: auth.cargando,
                onPressed: () async {
                  if (!form.currentState!.validate()) return;
                  final ok = await auth.cambiarCorreo(correo.text, clave.text);
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
  if (cambiado == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Listo: tu correo cambió.'),
    ));
  }
}
