import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../nucleo/tema.dart';
import 'responsivo.dart';
import 'redes_sociais.dart';

class RodapeWeb extends StatelessWidget {
  const RodapeWeb({super.key});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final computador = context.ehComputador;
    final estiloTitulo = computador
        ? TemaNice.tituloRodape()
        : texto.headlineLarge?.copyWith(color: TemaNice.branco);
    final corDestaque = estiloTitulo?.copyWith(color: TemaNice.vermelhoVivo);

    final marca = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 6, color: TemaNice.vermelhoVivo),
          const SizedBox(width: 28),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    style: texto.labelLarge?.copyWith(color: TemaNice.vermelhoVivo, letterSpacing: 1),
                    children: [
                      const TextSpan(text: 'STREET CULTURE '),
                      TextSpan(text: '/ 001', style: texto.labelLarge?.copyWith(color: TemaNice.vermelhoVivo, fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text.rich(
                  TextSpan(
                    style: estiloTitulo,
                    children: [
                      const TextSpan(text: 'YOUR STYLE'),
                      TextSpan(text: '.\n', style: corDestaque),
                      const TextSpan(text: 'YOUR IDENTITY'),
                      TextSpan(text: '.', style: corDestaque),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Vista sua identidade. Explore a NICE.', style: TemaNice.linkRodape()),
              ],
            ),
          ),
        ],
      ),
    );

    const colunas = Wrap(
      spacing: 96,
      runSpacing: 28,
      children: [
        _ColunaRodape(titulo: 'EXPLORE', links: [
          _LinkRodape('Novidades', '/novidades'),
          _LinkRodape('Catálogo', '/catalogo'),
          _LinkRodape('Carrinho', '/carrinho'),
          _LinkRodape('Minha conta', '/perfil'),
        ]),
        _ColunaRodape(titulo: 'NICE', links: [
          _LinkRodape('Sobre nós', '/sobre'),
          _LinkRodape('Contato', null),
          _LinkRodape('Entrega e devoluções', null),
          _LinkRodape('Privacidade e termos', null),
        ]),
      ],
    );

    final slogan = Row(
      children: [
        Flexible(child: Text('STREETWEAR WITHOUT LIMITS.', style: TemaNice.espacado())),
        const SizedBox(width: 24),
        const Spacer(),
        Container(width: computador ? 128 : 48, height: 3, color: TemaNice.vermelhoVivo),
      ],
    );
    final barraInferior = computador
        ? Row(
            children: [
              const RedesSociais(claro: true),
              Container(width: 1, height: 40, margin: const EdgeInsets.symmetric(horizontal: 28), color: TemaNice.linhaRodape),
              Expanded(child: slogan),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [const RedesSociais(claro: true), const SizedBox(height: 16), slogan],
          );

    return Container(
      width: double.infinity,
      color: TemaNice.preto,
      padding: EdgeInsets.only(top: computador ? 72 : 48, bottom: 28),
      child: ConteudoCentralizado(
        conteudo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (computador)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 5, child: Align(alignment: Alignment.centerLeft, child: marca)),
                    const VerticalDivider(color: TemaNice.linhaRodape, width: 64),
                    const Expanded(flex: 4, child: colunas),
                  ],
                ),
              )
            else ...[
              marca,
              const SizedBox(height: 36),
              colunas,
            ],
            const SizedBox(height: 48),
            const Divider(color: TemaNice.linhaRodape),
            const SizedBox(height: 24),
            barraInferior,
            const SizedBox(height: 24),
            const Divider(color: TemaNice.linhaRodape),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '© ${DateTime.now().year} NICE. Todos os direitos reservados.',
                    style: texto.bodySmall?.copyWith(color: TemaNice.cinzaMedio),
                  ),
                ),
                Text('JP / BR', style: texto.labelLarge?.copyWith(color: TemaNice.vermelhoVivo)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Um link do rodapé.
/// Sem caminho o link aparece mas não abre nada.
class _LinkRodape {
  const _LinkRodape(this.rotulo, this.caminho);
  final String rotulo;
  final String? caminho;
}

class _ColunaRodape extends StatelessWidget {
  const _ColunaRodape({required this.titulo, required this.links});

  final String titulo;
  final List<_LinkRodape> links;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(titulo, style: texto.titleLarge?.copyWith(color: TemaNice.branco, letterSpacing: 1)),
        const SizedBox(height: 18),
        for (final link in links)
          InkWell(
            onTap: link.caminho == null ? null : () => context.go(link.caminho!),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(link.rotulo, style: TemaNice.linkRodape()),
            ),
          ),
      ],
    );
  }
}
