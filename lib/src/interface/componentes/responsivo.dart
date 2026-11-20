import 'package:flutter/material.dart';

import '../../nucleo/tema.dart';

extension ContextoResponsivo on BuildContext {
  double get larguraTela => MediaQuery.sizeOf(this).width;
  bool get ehComputador => larguraTela >= TemaNice.larguraComputador;
  bool get ehTablet => larguraTela >= TemaNice.larguraTablet && !ehComputador;
  bool get ehCelular => larguraTela < TemaNice.larguraTablet;
  double get margemPagina => ehComputador ? 48 : (ehTablet ? 32 : 20);
}

/// Altura visível da página.
/// Usada para o banner do topo caber inteiro na tela.
class AlturaVisivel extends InheritedWidget {
  const AlturaVisivel({super.key, required this.altura, required super.child});

  final double altura;

  static double? daArvore(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AlturaVisivel>()?.altura;

  @override
  bool updateShouldNotify(AlturaVisivel oldWidget) => oldWidget.altura != altura;
}

class ConteudoCentralizado extends StatelessWidget {
  const ConteudoCentralizado({super.key, required this.conteudo, this.larguraMaxima = TemaNice.larguraMaximaConteudo, this.margem});

  final Widget conteudo;
  final double larguraMaxima;
  final EdgeInsetsGeometry? margem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: larguraMaxima),
        child: Padding(
          padding: margem ?? EdgeInsets.symmetric(horizontal: context.margemPagina),
          child: conteudo,
        ),
      ),
    );
  }
}
