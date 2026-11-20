// Caminho de navegação da página do produto.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../nucleo/tema.dart';

/// Um pedaço do caminho.
/// Sem destino ele é a página atual.
class ItemTrilha {
  const ItemTrilha(this.rotulo, [this.caminho]);

  final String rotulo;

  final String? caminho;
}

/// Mostra Home depois Catálogo depois a categoria e o produto com links.
class TrilhaNavegacao extends StatelessWidget {
  const TrilhaNavegacao({super.key, required this.itens});

  final List<ItemTrilha> itens;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final estiloLink = texto.labelMedium;
    final estiloAtual = texto.labelMedium?.copyWith(color: TemaNice.cinzaTexto);

    return Semantics(
      label: 'Navegação estrutural',
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 4,
        children: [
          for (var i = 0; i < itens.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.chevron_right, size: 16, color: TemaNice.cinzaMedio),
              ),
            if (itens[i].caminho == null)
              Text(itens[i].rotulo.toUpperCase(), style: estiloAtual)
            else
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go(itens[i].caminho!),
                  child: Text(itens[i].rotulo.toUpperCase(), style: estiloLink),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
