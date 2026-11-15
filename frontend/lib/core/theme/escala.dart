import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/auth/domain/preferencias.dart';

/// Escala de la interfaz en UN solo lugar (Fase 3, ADR-0016).
///
/// - [interfaz]: toda la app (texto, botones, barra inferior, íconos, márgenes) se dibuja este
///   tanto más grande. No hay números sueltos repartidos por las pantallas.
/// - Texto: se respeta el tamaño de texto del SISTEMA, multiplicado por la preferencia de la
///   persona (Normal / Grande / Extra grande, guardada en el servidor), con tope en
///   [textoMaximo] para que nada se desborde.
class Escala {
  Escala._();

  /// "Un poco más grande" (antes 0,9; ver ADR-0013 y ADR-0016).
  static const double interfaz = 1.10;

  /// Tope del factor de texto (sistema × preferencia), sin contar [interfaz].
  static const double textoMaximo = 1.4;

  /// Factor de texto efectivo: sistema × preferencia, sin pasar del tope.
  static double factorTexto(TextScaler sistema, TamanoTexto preferencia) {
    final delSistema = sistema.scale(10) / 10;
    return math.min(delSistema * preferencia.factor, textoMaximo);
  }
}

/// Aplica [Escala.interfaz] a todo lo que cuelga del MaterialApp (pantallas, hojas y diálogos)
/// y el factor de texto. La app se diseña sobre un lienzo de tamaño / escala y se pinta
/// ampliada; los toques y el teclado se convierten solos.
class EscalaGlobal extends StatelessWidget {
  const EscalaGlobal({
    super.key,
    required this.child,
    this.tamanoTexto = TamanoTexto.normal,
    this.factor = Escala.interfaz,
  });

  final Widget child;
  final TamanoTexto tamanoTexto;
  final double factor;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final lienzo = mq.size / factor;
    final texto = Escala.factorTexto(mq.textScaler, tamanoTexto);
    return OverflowBox(
      alignment: Alignment.topLeft,
      minWidth: lienzo.width,
      maxWidth: lienzo.width,
      minHeight: lienzo.height,
      maxHeight: lienzo.height,
      child: Transform.scale(
        scale: factor,
        alignment: Alignment.topLeft,
        child: MediaQuery(
          data: mq.copyWith(
            size: lienzo,
            devicePixelRatio: mq.devicePixelRatio * factor,
            padding: mq.padding / factor,
            viewPadding: mq.viewPadding / factor,
            viewInsets: mq.viewInsets / factor,
            systemGestureInsets: mq.systemGestureInsets / factor,
            textScaler: TextScaler.linear(texto),
          ),
          child: child,
        ),
      ),
    );
  }
}
