import 'package:flutter/material.dart';

import '../../nucleo/imagens.dart';

class LogoNice extends StatelessWidget {
  const LogoNice({super.key, this.pequena = false, this.claro = false});

  final bool pequena;

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
