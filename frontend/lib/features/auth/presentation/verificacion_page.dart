import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/uber_widgets.dart';
import '../../../shared/utb_ui.dart';
import 'auth_controller.dart';
import 'cambiar_correo_sheet.dart';

/// "Revisa tu correo": se muestra justo después de crear la cuenta (ADR-0014). La cuenta ya
/// existe y puede entrar a consultar; para solicitar salones debe abrir el enlace del correo.
class VerificacionPage extends StatelessWidget {
  const VerificacionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = sl<AuthController>();
    return Scaffold(
      body: ListenableBuilder(
        listenable: auth,
        builder: (context, _) {
          final correo = auth.usuario?.email ?? '';
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              EncabezadoDegradado(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.degradado,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.mark_email_unread_rounded, size: 30),
                    ),
                    const SizedBox(height: 16),
                    const Text('Revisa tu correo',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        text: 'Te enviamos un enlace a ',
                        children: [
                          TextSpan(
                            text: correo,
                            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          const TextSpan(text: '. Ábrelo para activar tu cuenta.'),
                        ],
                      ),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Paso(n: 1, texto: 'Abre el correo de UTB Tracker (mira también en spam).'),
                    const _Paso(n: 2, texto: 'Toca «Confirmar mi correo». El enlace vence en 24 horas.'),
                    const _Paso(n: 3, texto: 'Vuelve aquí y toca «Ya lo verifiqué».'),
                    const SizedBox(height: 8),
                    const Text(
                      'Mientras tanto puedes entrar y consultar los salones, pero no solicitarlos.',
                      style: TextStyle(color: AppColors.textoTenue, fontSize: 13),
                    ),
                    if (auth.aviso != null) ...[
                      const SizedBox(height: 14),
                      _Mensaje(texto: auth.aviso!, color: AppColors.disponible),
                    ],
                    if (auth.error != null) ...[
                      const SizedBox(height: 14),
                      _Mensaje(texto: auth.error!, color: AppColors.danado),
                    ],
                    const SizedBox(height: 20),
                    BotonPildora(
                      texto: 'Ya lo verifiqué',
                      icono: Icons.verified_rounded,
                      cargando: auth.cargando,
                      onPressed: auth.comprobarVerificacion,
                    ),
                    const SizedBox(height: 10),
                    BotonPildora(
                      texto: 'Reenviar correo',
                      icono: Icons.forward_to_inbox_rounded,
                      estilo: EstiloBoton.secundario,
                      onPressed: auth.cargando ? null : auth.reenviarVerificacion,
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: auth.cargando ? null : () => mostrarCambiarCorreo(context),
                      child: const Text('¿Escribiste mal el correo? Cámbialo'),
                    ),
                    TextButton(
                      onPressed: auth.continuarSinVerificar,
                      child: const Text('Entrar sin verificar por ahora',
                          style: TextStyle(color: AppColors.textoSuave)),
                    ),
                    TextButton(
                      onPressed: auth.cerrarSesion,
                      child: const Text('Cerrar sesión',
                          style: TextStyle(color: AppColors.textoTenue)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Paso extends StatelessWidget {
  const _Paso({required this.n, required this.texto});
  final int n;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.seleccion,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$n',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.indigoClaro)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 14.5, height: 1.35))),
        ],
      ),
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje({required this.texto, required this.color});
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(texto, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// Aviso fijo para cuentas sin verificar (en la pantalla principal). No depende solo del
/// color: tiene ícono y texto.
class AvisoVerificacion extends StatelessWidget {
  const AvisoVerificacion({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = sl<AuthController>();
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        if (!auth.autenticado || auth.correoVerificado) return const SizedBox.shrink();
        return Semantics(
          container: true,
          label: 'Tu correo no está verificado',
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
            decoration: BoxDecoration(
              color: const Color(0xF2261E0D),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.prestado.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                const Icon(Icons.mark_email_unread_rounded, color: AppColors.prestado, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Verifica tu correo para solicitar salones.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: auth.cargando ? null : auth.comprobarVerificacion,
                  child: const Text('Ya lo hice'),
                ),
                TextButton(
                  onPressed: auth.cargando ? null : auth.reenviarVerificacion,
                  child: const Text('Reenviar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
