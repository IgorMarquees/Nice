// Preço e selos dos produtos.

import 'package:flutter/material.dart';

import '../../dados/produto.dart';
import '../../nucleo/tema.dart';
import '../../nucleo/formatadores.dart';

/// Mostra o preço cheio riscado e o preço com desconto ao lado.
class EtiquetaPreco extends StatelessWidget {
  const EtiquetaPreco({super.key, required this.produto, this.grande = false});

  final Produto produto;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final atual = Text(formatarMoeda(produto.precoFinal), style: TemaNice.preco(grande: grande));
    if (!produto.temDesconto) return atual;

    return Wrap(
      spacing: grande ? 12 : 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(formatarMoeda(produto.preco), style: TemaNice.precoAntigo(grande: grande)),
        atual,
      ],
    );
  }
}

/// Etiqueta vermelha com a porcentagem de desconto.
class SeloDesconto extends StatelessWidget {
  const SeloDesconto({super.key, required this.percentual});

  final int percentual;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TemaNice.vermelhoVivo,
        borderRadius: BorderRadius.circular(TemaNice.raio / 2),
      ),
      child: Text('-$percentual%', style: TemaNice.selo()),
    );
  }
}

/// Selo de texto como Novo ou Esgotado.
class SeloTexto extends StatelessWidget {
  const SeloTexto({super.key, required this.rotulo, this.escuro = false});

  final String rotulo;
  final bool escuro;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      color: escuro ? TemaNice.grafite : TemaNice.vermelho,
      child: Text(rotulo.toUpperCase(), style: TemaNice.selo()),
    );
  }
}
