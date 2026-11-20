// Moldura do site.

import 'package:flutter/material.dart';

import '../componentes/barra_navegacao_web.dart';

/// Barra de navegação fixa no topo e a página abaixo.
/// A rolagem e o rodapé ficam dentro de cada página.
class MolduraWeb extends StatelessWidget {
  const MolduraWeb({super.key, required this.local, required this.conteudo});

  final String local;
  final Widget conteudo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: MenuLateralWeb(local: local),
      body: Column(
        children: [
          BarraNavegacaoWeb(local: local),
          Expanded(child: conteudo),
        ],
      ),
    );
  }
}
