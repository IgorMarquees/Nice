import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/nice_theme.dart';
import 'responsive.dart';
import 'social_links.dart';

/// Rodapé do site: faixa vermelha, slogan, colunas de links e barra inferior.
class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final desktop = context.isDesktop;
    final titleStyle = desktop
        ? NiceTheme.footerTitle()
        : text.headlineLarge?.copyWith(color: NiceTheme.white);
    final accent = titleStyle?.copyWith(color: NiceTheme.brightRed);

    final brand = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 6, color: NiceTheme.brightRed),
          const SizedBox(width: 28),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    style: text.labelLarge?.copyWith(color: NiceTheme.brightRed, letterSpacing: 1),
                    children: [
                      const TextSpan(text: 'STREET CULTURE '),
                      TextSpan(text: '/ 001', style: text.labelLarge?.copyWith(color: NiceTheme.brightRed, fontWeight: FontWeight.w400)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text.rich(
                  TextSpan(
                    style: titleStyle,
                    children: [
                      const TextSpan(text: 'YOUR STYLE'),
                      TextSpan(text: '.\n', style: accent),
                      const TextSpan(text: 'YOUR IDENTITY'),
                      TextSpan(text: '.', style: accent),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Vista sua identidade. Explore a NICE.', style: NiceTheme.footerLink()),
              ],
            ),
          ),
        ],
      ),
    );

    const columns = Wrap(
      spacing: 96,
      runSpacing: 28,
      children: [
        _FooterColumn(title: 'EXPLORE', links: [
          _FooterLinkData('Novidades', '/novidades'),
          _FooterLinkData('Catálogo', '/catalogo'),
          _FooterLinkData('Carrinho', '/carrinho'),
          _FooterLinkData('Minha conta', '/perfil'),
        ]),
        _FooterColumn(title: 'NICE', links: [
          _FooterLinkData('Sobre nós', '/sobre'),
          _FooterLinkData('Contato', null),
          _FooterLinkData('Entrega e devoluções', null),
          _FooterLinkData('Privacidade e termos', null),
        ]),
      ],
    );

    final slogan = Row(
      children: [
        Flexible(child: Text('STREETWEAR WITHOUT LIMITS.', style: NiceTheme.spaced())),
        const SizedBox(width: 24),
        const Spacer(),
        Container(width: desktop ? 128 : 48, height: 3, color: NiceTheme.brightRed),
      ],
    );
    // Redes sociais + slogan (no celular/tablet, um embaixo do outro).
    final bottomBar = desktop
        ? Row(
            children: [
              const SocialLinks(light: true),
              Container(width: 1, height: 40, margin: const EdgeInsets.symmetric(horizontal: 28), color: NiceTheme.footerLine),
              Expanded(child: slogan),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [const SocialLinks(light: true), const SizedBox(height: 16), slogan],
          );

    return Container(
      width: double.infinity,
      color: NiceTheme.black,
      padding: EdgeInsets.only(top: desktop ? 72 : 48, bottom: 28),
      child: ContentWrapper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (desktop)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 5, child: Align(alignment: Alignment.centerLeft, child: brand)),
                    const VerticalDivider(color: NiceTheme.footerLine, width: 64),
                    const Expanded(flex: 4, child: columns),
                  ],
                ),
              )
            else ...[
              brand,
              const SizedBox(height: 36),
              columns,
            ],
            const SizedBox(height: 48),
            const Divider(color: NiceTheme.footerLine),
            const SizedBox(height: 24),
            bottomBar,
            const SizedBox(height: 24),
            const Divider(color: NiceTheme.footerLine),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '© ${DateTime.now().year} NICE. Todos os direitos reservados.',
                    style: text.bodySmall?.copyWith(color: NiceTheme.midGray),
                  ),
                ),
                Text('JP / BR', style: text.labelLarge?.copyWith(color: NiceTheme.brightRed)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterLinkData {
  const _FooterLinkData(this.label, this.path);
  final String label;
  final String? path;
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.title, required this.links});

  final String title;
  final List<_FooterLinkData> links;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: text.titleLarge?.copyWith(color: NiceTheme.white, letterSpacing: 1)),
        const SizedBox(height: 18),
        for (final link in links)
          InkWell(
            onTap: link.path == null ? null : () => context.go(link.path!),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(link.label, style: NiceTheme.footerLink()),
            ),
          ),
      ],
    );
  }
}
