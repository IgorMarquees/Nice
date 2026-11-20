import 'package:flutter/material.dart';

import '../../nucleo/tema.dart';

class BotaoPrincipal extends StatelessWidget {
  const BotaoPrincipal({
    super.key,
    required this.rotulo,
    required this.aoPressionar,
    this.carregando = false,
    this.icone,
  });

  final String rotulo;
  final VoidCallback? aoPressionar;
  final bool carregando;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final conteudo = carregando
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: TemaNice.branco),
          )
        : Text(rotulo);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: icone == null || carregando
          ? FilledButton(onPressed: carregando ? null : aoPressionar, child: conteudo)
          : FilledButton.icon(onPressed: aoPressionar, icon: Icon(icone), label: conteudo),
    );
  }
}
