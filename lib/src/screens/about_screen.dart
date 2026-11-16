import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/assets.dart';
import '../widgets/banner_image.dart';
import '../widgets/responsive.dart';
import '../widgets/social_links.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final desktop = context.isDesktop;

    final headline = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('01 / OUR IDENTITY', style: text.labelMedium),
        const SizedBox(height: 12),
        Text('SEU ESTILO.', style: desktop ? text.displayMedium : text.headlineLarge),
        Text(
          'SUAS REGRAS.',
          style: (desktop ? text.displayMedium : text.headlineLarge)?.copyWith(color: text.labelMedium?.color),
        ),
      ],
    );
    final body = Text(
      'A NICE nasce da conexão entre streetwear, referências japonesas e expressão individual. '
      'Mais do que acompanhar tendências, vestir-se é construir uma identidade própria. '
      'A estética japonesa, os cenários urbanos e a atitude das ruas são as nossas maiores inspirações.',
      style: text.bodyLarge,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BannerImage(
          asset: NiceAssets.aboutTop,
          fitViewport: true,
          aspectRatio: 2880 / 1000,
          label: 'Mais que roupa. Uma identidade.',
        ),
        // Espaço entre os dois banners (não ficam colados).
        SizedBox(height: desktop ? 56 : 24),
        const BannerImage(asset: NiceAssets.aboutStrip, aspectRatio: 2624 / 874),
        SizedBox(height: desktop ? 88 : 40),
        ContentWrapper(
          child: desktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: headline),
                    const SizedBox(width: 64),
                    Expanded(child: body),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [headline, const SizedBox(height: 20), body],
                ),
        ),
        // No app (sem rodapé de site), as redes sociais aparecem aqui.
        if (!kIsWeb) ...[
          const SizedBox(height: 32),
          ContentWrapper(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text('SIGA A NICE', style: text.labelMedium), const SocialLinks()],
            ),
          ),
        ],
        SizedBox(height: desktop ? 88 : 40),
        const BannerImage(asset: NiceAssets.aboutCta, aspectRatio: 2624 / 732, label: 'Não vista apenas. Expresse.'),
      ],
    );
  }
}
