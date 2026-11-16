import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/nice_theme.dart';

class _Social {
  const _Social(this.name, this.icon);
  final String name;
  final FaIconData icon;
}

const _networks = [
  _Social('Instagram', FontAwesomeIcons.instagram),
  _Social('TikTok', FontAwesomeIcons.tiktok),
  _Social('Facebook', FontAwesomeIcons.facebook),
  _Social('X', FontAwesomeIcons.xTwitter),
  _Social('YouTube', FontAwesomeIcons.youtube),
];

/// Ícones das redes sociais da NICE.
/// Ainda não há perfis oficiais: os ícones não levam a lugar nenhum.
class SocialLinks extends StatelessWidget {
  const SocialLinks({super.key, this.light = false, this.size = 22});

  /// true = ícones brancos (fundos escuros, como o rodapé).
  final bool light;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = light ? NiceTheme.white : NiceTheme.charcoal;
    return Wrap(
      spacing: 4,
      children: [
        for (final network in _networks)
          IconButton(
            tooltip: network.name,
            // Sem destino por enquanto (perfis ainda não criados).
            onPressed: () {},
            hoverColor: NiceTheme.brightRed.withValues(alpha: 0.15),
            icon: FaIcon(network.icon, size: size, color: color, semanticLabel: network.name),
          ),
      ],
    );
  }
}
