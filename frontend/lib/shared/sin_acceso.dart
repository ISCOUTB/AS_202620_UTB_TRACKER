import 'package:flutter/material.dart';

import '../core/di/injection.dart';
import '../core/error/api_exception.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_controller.dart';

/// ¿El servidor dijo "no tienes permiso"? (ADR-0018)
bool esSinPermiso(Object error) => error is ApiException && error.statusCode == 403;

/// Pantalla amable cuando alguien llega a algo que su rol no permite: un enlace directo, un
/// rol que cambió con la app abierta o un 403 del servidor. Nunca un error crudo.
class SinAcceso extends StatelessWidget {
  const SinAcceso({super.key, this.detalle, this.onVolver});

  final String? detalle;
  final VoidCallback? onVolver;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'No tienes acceso a esto',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.superficieAlta,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.lock_outline_rounded, size: 32, color: AppColors.primarioClaro),
            ),
            const SizedBox(height: 16),
            const Text('No tienes acceso a esto',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              detalle ??
                  'Tu rol no incluye esta sección. Si te cambiaron el rol hace poco, ya '
                      'actualizamos tu perfil: vuelve al inicio para ver tus opciones.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textoSuave, fontSize: 14, height: 1.35),
            ),
            if (onVolver != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                style: FilledButton.styleFrom(shape: const StadiumBorder()),
                onPressed: onVolver,
                child: const Text('Volver al inicio'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Muestra [child] solo si los permisos con los que se dibuja la app incluyen [permiso].
/// Si el rol cambia en caliente, la pantalla se cierra sola en "sin acceso".
class ConPermiso extends StatelessWidget {
  const ConPermiso({super.key, required this.permiso, required this.child, this.auth});

  final String permiso;
  final Widget child;
  final AuthController? auth;

  @override
  Widget build(BuildContext context) {
    final a = auth ?? sl<AuthController>();
    return ListenableBuilder(
      listenable: a,
      builder: (context, _) => a.permisos.puede(permiso)
          ? child
          : Center(
              child: SinAcceso(
                onVolver: Navigator.of(context).canPop()
                    ? () => Navigator.of(context).popUntil((r) => r.isFirst)
                    : null,
              ),
            ),
    );
  }
}

/// Ante un 403, vuelve a leer el perfil (el rol pudo cambiar) para que la navegación se
/// ajuste sola. Lo llaman los controladores de las pantallas por rol.
Future<void> alPerderPermiso() async {
  if (sl.isRegistered<AuthController>()) await sl<AuthController>().actualizarPerfil();
}
