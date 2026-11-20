// Página sobre nós.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../nucleo/imagens.dart';
import '../componentes/imagem_banner.dart';
import '../componentes/responsivo.dart';
import '../componentes/redes_sociais.dart';

/// Banners e o texto que conta a história da marca.
class TelaSobre extends StatelessWidget {
  const TelaSobre({super.key});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final computador = context.ehComputador;

    final manchete = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('01 / OUR IDENTITY', style: texto.labelMedium),
        const SizedBox(height: 12),
        Text('SEU ESTILO.', style: computador ? texto.displayMedium : texto.headlineLarge),
        Text(
          'SUAS REGRAS.',
          style: (computador ? texto.displayMedium : texto.headlineLarge)?.copyWith(color: texto.labelMedium?.color),
        ),
      ],
    );
    final corpo = Text(
      'A NICE nasce da conexão entre streetwear, referências japonesas e expressão individual. '
      'Mais do que acompanhar tendências, vestir-se é construir uma identidade própria. '
      'A estética japonesa, os cenários urbanos e a atitude das ruas são as nossas maiores inspirações.',
      style: texto.bodyLarge,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ImagemBanner(
          arte: ImagensNice.sobreTopo,
          caberNaTela: true,
          proporcao: 2880 / 1000,
          rotulo: 'Mais que roupa. Uma identidade.',
        ),
        SizedBox(height: computador ? 56 : 24),
        const ImagemBanner(arte: ImagensNice.sobreFaixa, proporcao: 2624 / 874),
        SizedBox(height: computador ? 88 : 40),
        ConteudoCentralizado(
          conteudo: computador
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: manchete),
                    const SizedBox(width: 64),
                    Expanded(child: corpo),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [manchete, const SizedBox(height: 20), corpo],
                ),
        ),
        if (!kIsWeb) ...[
          const SizedBox(height: 32),
          ConteudoCentralizado(
            conteudo: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text('SIGA A NICE', style: texto.labelMedium), const RedesSociais()],
            ),
          ),
        ],
        SizedBox(height: computador ? 88 : 40),
        const ImagemBanner(arte: ImagensNice.sobreFinal, proporcao: 2624 / 732, rotulo: 'Não vista apenas. Expresse.'),
      ],
    );
  }
}
