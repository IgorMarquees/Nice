// Logo da NICE.

import 'package:flutter/material.dart';

import '../../nucleo/imagens.dart';

/// Logo em versão clara ou escura e em tamanho normal ou pequeno.
class LogoNice extends StatelessWidget {
  const LogoNice({super.key, this.pequena = false, this.claro = false});

  final bool pequena;

  /// Versão branca para fundos escuros.
  final bool claro;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      claro ? ImagensNice.logoClara : ImagensNice.logoEscura,
      height: pequena ? 44 : 96,
      fit: BoxFit.contain,
    );
  }
}
