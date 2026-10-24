/// Rutas de las figuras (ilustraciones SVG propias del proyecto).
/// Todas viven en `assets/figuras/` para poder reemplazarlas sin tocar el código.
class Figuras {
  Figuras._();

  static const _base = 'assets/figuras';

  // Categorías de recurso
  static const videoBeam = '$_base/video_beam.svg';
  static const computador = '$_base/computador.svg';
  static const aireAc = '$_base/aire_ac.svg';
  static const tv = '$_base/tv.svg';
  static const audio = '$_base/audio.svg';
  static const otros = '$_base/otros.svg';

  // Marca y estados vacíos
  static const logo = '$_base/logo.svg';
  static const vacio = '$_base/vacio.svg';
  static const mantenimiento = '$_base/mantenimiento.svg';

  // Tarjetas del carrusel "Planifica tu próximo préstamo"
  static const tarjetaPrestar = '$_base/tarjeta_prestar.svg';
  static const tarjetaDevolver = '$_base/tarjeta_devolver.svg';
  static const tarjetaMantenimiento = '$_base/tarjeta_mantenimiento.svg';
}
