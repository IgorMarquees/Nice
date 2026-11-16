import 'package:flutter/material.dart';

/// Banner pronto (a arte já contém o texto). Mantém a proporção original
/// para não cortar o texto e, com [onTap], vira um link clicável.
class BannerImage extends StatelessWidget {
  const BannerImage({
    super.key,
    required this.asset,
    required this.aspectRatio,
    this.onTap,
    this.label,
  });

  final String asset;

  /// largura / altura da arte original.
  final double aspectRatio;
  final VoidCallback? onTap;

  /// Texto para leitores de tela (o texto da arte não é acessível).
  final String? label;

  @override
  Widget build(BuildContext context) {
    final image = AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Decodifica no tamanho exibido (artes de 2880 px pesam no celular).
          // Arredonda em degraus para não recarregar a cada pixel de resize.
          final dpr = MediaQuery.devicePixelRatioOf(context);
          final target = ((constraints.maxWidth * dpr) / 480).ceil() * 480;
          return Image.asset(
            asset,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            cacheWidth: target.clamp(480, 2880),
            gaplessPlayback: true,
          );
        },
      ),
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
