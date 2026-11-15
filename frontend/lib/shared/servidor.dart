import 'package:flutter/material.dart';

import '../core/config/api_config.dart';
import '../core/di/injection.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_controller.dart';

/// Píldora "Oficial (nube) · Conectado": dice SIEMPRE a qué servidor habla la app, para que
/// nadie se registre en uno y entre en otro (ADR-0014). Al tocarla se ve la dirección completa
/// y, en compilaciones de desarrollo, se puede cambiar de servidor.
class InsigniaServidor extends StatelessWidget {
  const InsigniaServidor({super.key, this.compacta = false});

  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final auth = sl<AuthController>();
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final ok = auth.servidorOk;
        final color = ok == null
            ? AppColors.neutro
            : ok
                ? AppColors.disponible
                : AppColors.danado;
        final estado = ok == null
            ? 'comprobando…'
            : ok
                ? 'conectado'
                : 'sin conexión';
        return Semantics(
          button: true,
          label: 'Servidor ${ApiConfig.describir()}, $estado. Toca para ver detalles.',
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => mostrarServidor(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x55000000),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      compacta ? estado : '${ApiConfig.describir()} · $estado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Hoja con el servidor actual y, si la compilación lo permite, opciones para cambiarlo.
Future<void> mostrarServidor(BuildContext context) {
  final auth = sl<AuthController>();
  final manual = TextEditingController(
    text: ApiConfig.sugeridos.containsKey(ApiConfig.baseUrl) ? '' : ApiConfig.baseUrl,
  );
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Servidor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          SelectableText(ApiConfig.baseUrl,
              style: const TextStyle(color: AppColors.primarioClaro, fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            ApiConfig.esOficial
                ? 'Es el servidor oficial: aquí están las cuentas reales.'
                : 'No es el servidor oficial: las cuentas de aquí no existen en la nube.',
            style: const TextStyle(color: AppColors.textoSuave, fontSize: 13),
          ),
          if (!ApiConfig.permiteCambiarServidor) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                auth.comprobarServidor();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Comprobar conexión'),
            ),
          ] else ...[
            const SizedBox(height: 14),
            const Text('Cambiar (solo en compilaciones de desarrollo)',
                style: TextStyle(color: AppColors.textoTenue, fontSize: 12)),
            const SizedBox(height: 6),
            for (final e in ApiConfig.sugeridos.entries)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  e.key == ApiConfig.baseUrl
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: AppColors.primarioClaro,
                ),
                title: Text(e.value),
                subtitle: Text(e.key, style: const TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  auth.cambiarServidor(e.key == ApiConfig.porDefecto ? null : e.key);
                },
              ),
            TextField(
              controller: manual,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Otra dirección',
                hintText: 'http://192.168.1.17:8000',
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () {
                final url = manual.text.trim();
                if (!url.startsWith('http')) return;
                Navigator.pop(ctx);
                auth.cambiarServidor(url);
              },
              child: const Text('Usar esta dirección'),
            ),
          ],
        ],
      ),
    ),
  ).whenComplete(manual.dispose);
}
