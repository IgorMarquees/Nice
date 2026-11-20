// Ícones das redes sociais.

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../nucleo/tema.dart';

/// Uma rede social com nome e ícone.
class _Rede {
  const _Rede(this.nome, this.icone);
  final String nome;
  final FaIconData icone;
}

/// Redes mostradas no rodapé no perfil e no Sobre.
const _redes = [
  _Rede('Instagram', FontAwesomeIcons.instagram),
  _Rede('TikTok', FontAwesomeIcons.tiktok),
  _Rede('Facebook', FontAwesomeIcons.facebook),
  _Rede('X', FontAwesomeIcons.xTwitter),
  _Rede('YouTube', FontAwesomeIcons.youtube),
];

/// Ícones das redes.
/// Ainda não há perfis oficiais por isso não levam a lugar nenhum.
class RedesSociais extends StatelessWidget {
  const RedesSociais({super.key, this.claro = false, this.tamanho = 22});

  final bool claro;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    final cor = claro ? TemaNice.branco : TemaNice.grafite;
    return Wrap(
      spacing: 4,
      children: [
        for (final rede in _redes)
          IconButton(
            tooltip: rede.nome,
            onPressed: () {},
            hoverColor: TemaNice.vermelhoVivo.withValues(alpha: 0.15),
            icon: FaIcon(rede.icone, size: tamanho, color: cor, semanticLabel: rede.nome),
          ),
      ],
    );
  }
}
