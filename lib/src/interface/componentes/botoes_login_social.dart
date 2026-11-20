import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../nucleo/configuracao.dart';
import '../../controladores/controlador_autenticacao.dart';

/// Mostra o botão do Google só no Android e na web.
class BotoesLoginSocial extends StatelessWidget {
  const BotoesLoginSocial({super.key});

  @override
  Widget build(BuildContext context) {
    final autenticacao = context.watch<ControladorAutenticacao>();
    final texto = Theme.of(context).textTheme;

    final botoes = <Widget>[
      if (Configuracao.mostrarLoginGoogle)
        _BotaoSocial(
          rotulo: 'Continuar com Google',
          icone: Icons.g_mobiledata,
          aoPressionar: autenticacao.carregando ? null : autenticacao.entrarComGoogle,
        ),
    ];
    if (botoes.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        ...botoes,
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('OU', style: texto.labelSmall),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _BotaoSocial extends StatelessWidget {
  const _BotaoSocial({required this.rotulo, required this.icone, required this.aoPressionar});

  final String rotulo;
  final IconData icone;
  final VoidCallback? aoPressionar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: aoPressionar,
          icon: Icon(icone, size: 28),
          label: Text(rotulo),
        ),
      ),
    );
  }
}
