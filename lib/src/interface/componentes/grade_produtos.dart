import 'dart:math';

import 'package:flutter/material.dart';

import '../../dados/produto.dart';
import 'cartao_produto.dart';

int colunasProdutos(double largura, {int maxColunas = 4}) =>
    min(maxColunas, largura >= 900 ? 4 : (largura >= 600 ? 3 : 2));

/// Monta linhas de cards com a altura do conteúdo para o texto nunca estourar.
class GradeProdutos extends StatelessWidget {
  const GradeProdutos({super.key, required this.produtos, this.maxColunas = 4});

  final List<Produto> produtos;
  final int maxColunas;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, limites) {
        final colunas = colunasProdutos(limites.maxWidth, maxColunas: maxColunas);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var inicio = 0; inicio < produtos.length; inicio += colunas) ...[
              if (inicio > 0) const SizedBox(height: 32),
              LinhaProdutos(produtos: produtos.skip(inicio).take(colunas).toList(), colunas: colunas),
            ],
          ],
        );
      },
    );
  }
}

class LinhaProdutos extends StatelessWidget {
  const LinhaProdutos({super.key, required this.produtos, required this.colunas, this.espaco = 20});

  final List<Produto> produtos;
  final int colunas;
  final double espaco;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < colunas; i++) ...[
          if (i > 0) SizedBox(width: espaco),
          Expanded(
            child: i < produtos.length ? CartaoProduto(produto: produtos[i]) : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}
