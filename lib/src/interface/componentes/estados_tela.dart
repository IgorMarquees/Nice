import 'package:flutter/material.dart';

import '../../nucleo/tema.dart';

class Carregando extends StatelessWidget {
  const Carregando({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class EstadoVazio extends StatelessWidget {
  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    this.mensagem,
    this.textoAcao,
    this.aoAgir,
  });

  final IconData icone;
  final String titulo;
  final String? mensagem;
  final String? textoAcao;
  final VoidCallback? aoAgir;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 56, color: TemaNice.cinzaMedio),
            const SizedBox(height: 16),
            Text(titulo, style: texto.headlineSmall, textAlign: TextAlign.center),
            if (mensagem != null) ...[
              const SizedBox(height: 8),
              Text(mensagem!, style: texto.bodyMedium, textAlign: TextAlign.center),
            ],
            if (textoAcao != null) ...[
              const SizedBox(height: 24),
              FilledButton(onPressed: aoAgir, child: Text(textoAcao!)),
            ],
          ],
        ),
      ),
    );
  }
}

class MensagemFormulario extends StatelessWidget {
  const MensagemFormulario({super.key, required this.texto, this.ehErro = true});

  final String texto;
  final bool ehErro;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: ehErro ? TemaNice.vermelho : TemaNice.sucesso,
          fontWeight: FontWeight.w600,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(texto, style: estilo, textAlign: TextAlign.center),
    );
  }
}
