import 'package:flutter/material.dart';

import '../componentes/responsivo.dart';
import '../componentes/rodape_web.dart';
import 'moldura_web.dart';

/// Faz a página rolar e no site coloca o rodapé no fim.
/// A rolagem fica dentro da página para o navegador de rotas nunca ser recriado ao trocar de página.
class PaginaRolavel extends StatelessWidget {
  const PaginaRolavel({super.key, required this.conteudo});

  final Widget conteudo;

  @override
  Widget build(BuildContext context) {
    final web = context.findAncestorWidgetOfExactType<MolduraWeb>() != null;

    return LayoutBuilder(
      builder: (context, limites) => SingleChildScrollView(
        child: AlturaVisivel(
          altura: limites.maxHeight,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: limites.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (web)
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: limites.maxHeight * 0.6),
                    child: conteudo,
                  )
                else
                  conteudo,
                if (web) const RodapeWeb(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
