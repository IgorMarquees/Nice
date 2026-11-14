import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/nice_theme.dart';
import 'responsive.dart';

class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final titleStyle = text.displaySmall?.copyWith(color: NiceTheme.white);

    final brand = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STREET CULTURE / 001', style: text.labelMedium),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            style: titleStyle,
            children: [
              const TextSpan(text: 'YOUR STYLE'),
              TextSpan(text: '.\n', style: titleStyle?.copyWith(color: NiceTheme.brightRed)),
              const TextSpan(text: 'YOUR IDENTITY'),
              TextSpan(text: '.', style: titleStyle?.copyWith(color: NiceTheme.brightRed)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Vista sua identidade. Explore a NICE.',
          style: text.bodyMedium?.copyWith(color: NiceTheme.midGray),
        ),
      ],
    );

    final columns = Wrap(
      spacing: 64,
      runSpacing: 24,
      children: const [
        _FooterColumn(title: 'EXPLORE', links: [
          _FooterLinkData('Novidades', '/novidades'),
          _FooterLinkData('Categorias', '/catalogo'),
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

    return Container(
      width: double.infinity,
      color: NiceTheme.black,
      padding: const EdgeInsets.only(top: 56, bottom: 24),
      child: ContentWrapper(
        child: Column(
          children: [
            context.isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [brand, columns],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [brand, const SizedBox(height: 32), columns],
                  ),
            const SizedBox(height: 40),
            const Divider(color: NiceTheme.charcoal),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '© ${DateTime.now().year} NICE. Todos os direitos reservados. · STREETWEAR WITHOUT LIMITS.',
                style: text.labelSmall,
              ),
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
      children: [
        Text(title, style: text.labelLarge?.copyWith(color: NiceTheme.white)),
        const SizedBox(height: 12),
        for (final link in links)
          InkWell(
            onTap: link.path == null ? null : () => context.go(link.path!),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                link.label,
                style: text.bodyMedium?.copyWith(color: NiceTheme.midGray),
              ),
            ),
          ),
      ],
    );
  }
}
