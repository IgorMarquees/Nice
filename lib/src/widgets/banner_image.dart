import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'responsive.dart';

/// Banner pronto (a arte já contém o texto). Mantém a proporção original
/// para não cortar o texto e, com [onTap], vira um link clicável.
///
/// Com [fitViewport] (banners do topo das páginas), a altura nunca passa da
/// área visível da página: em telas largas/baixas a arte inteira aparece sem
/// rolar, centralizada, com as laterais preenchidas pela própria arte desfocada.
class BannerImage extends StatelessWidget {
  const BannerImage({
    super.key,
    required this.asset,
    required this.aspectRatio,
    this.onTap,
    this.label,
    this.fitViewport = false,
    this.appAspectRatio,
    this.appAlignment = Alignment.centerLeft,
  });

  final String asset;

  /// largura / altura da arte original.
  final double aspectRatio;
  final VoidCallback? onTap;

  /// Texto para leitores de tela (o texto da arte não é acessível).
  final String? label;
  final bool fitViewport;

  /// Só no app (Android/iOS): proporção mais alta para o banner. A arte é
  /// ampliada e recortada pela direita, mantendo o texto (à esquerda) maior
  /// e legível no celular.
  final double? appAspectRatio;

  /// Parte da arte mantida no recorte do app (padrão: o texto à esquerda).
  final Alignment appAlignment;

  /// Só no app e com largura de celular (tablet usa a proporção normal).
  static bool _useApp(BuildContext context, double? appAspectRatio) =>
      !kIsWeb && appAspectRatio != null && context.isCompact;

  /// Altura do banner para uma largura, limitada à área visível se pedido.
  static double heightFor(
    BuildContext context,
    double width,
    double aspectRatio, {
    required bool fitViewport,
    double? appAspectRatio,
  }) {
    if (_useApp(context, appAspectRatio)) return width / appAspectRatio!;
    final natural = width / aspectRatio;
    if (!fitViewport) return natural;
    final viewport = PageViewport.maybeOf(context) ?? MediaQuery.sizeOf(context).height;
    return natural > viewport ? viewport : natural;
  }

  @override
  Widget build(BuildContext context) {
    final image = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cropped = _useApp(context, appAspectRatio);
        final height = heightFor(context, width, aspectRatio, fitViewport: fitViewport, appAspectRatio: appAspectRatio);
        // Decodifica no tamanho exibido (artes de 2880 px pesam no celular).
        // Arredonda em degraus para não recarregar a cada pixel de resize.
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final cacheWidth = (((width * dpr) / 480).ceil() * 480).clamp(480, 2880);

        Widget picture({BoxFit fit = BoxFit.cover}) => Image.asset(
          asset,
          fit: fit,
          alignment: cropped ? appAlignment : Alignment.center,
          width: double.infinity,
          height: double.infinity,
          // Recortado, a arte aparece ampliada: decodifica proporcionalmente maior.
          cacheWidth: cropped ? (cacheWidth * aspectRatio / appAspectRatio!).round().clamp(480, 2880) : cacheWidth,
          gaplessPlayback: true,
        );

        final letterboxed = !cropped && height < width / aspectRatio - 0.5;
        return SizedBox(
          width: width,
          height: height,
          child: !letterboxed
              ? picture()
              : ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Laterais: a mesma arte ampliada e desfocada.
                      Transform.scale(
                        scale: 1.3,
                        child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40), child: picture()),
                      ),
                      Center(
                        child: AspectRatio(aspectRatio: aspectRatio, child: picture()),
                      ),
                    ],
                  ),
                ),
        );
      },
    );

    if (onTap == null) return Semantics(image: true, label: label, child: image);
    return Semantics(
      link: true,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: onTap, child: image),
      ),
    );
  }
}
