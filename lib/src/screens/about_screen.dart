import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/assets.dart';
import '../widgets/hero_banner.dart';
import '../widgets/responsive.dart';

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
        HeroBanner(
          image: NiceAssets.about,
          eyebrow: 'NICE® / Sobre',
          title: 'Mais que roupa.',
          accent: 'Uma identidade.',
          subtitle: 'Uma conexão entre a cultura urbana japonesa e a liberdade de expressar quem você é.',
          large: false,
          height: desktop ? 440 : 320,
        ),
        SizedBox(height: desktop ? 72 : 36),
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
        SizedBox(height: desktop ? 72 : 36),
        HeroBanner(
          image: NiceAssets.cta,
          eyebrow: 'NICE / Completo',
          title: 'Não vista apenas.',
          accent: 'Expresse.',
          subtitle: 'Explore o catálogo completo e encontre peças que representam você.',
          ctaLabel: 'Ver todos os produtos',
          onCta: () => context.go('/catalogo'),
          large: false,
          height: 380,
        ),
      ],
    );
  }
}
