import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../nucleo/tema.dart';
import 'responsivo.dart';

class CabecalhoSecao extends StatelessWidget {
  const CabecalhoSecao({
    super.key,
    required this.titulo,
    this.sobretitulo,
    this.textoAcao = 'Veja tudo',
    this.aoAgir,
  });

  final String titulo;
  final String? sobretitulo;
  final String textoAcao;
  final VoidCallback? aoAgir;

  @override
  Widget build(BuildContext context) {
    final grande = context.ehComputador;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sobretitulo != null) ...[
                Text(sobretitulo!, style: TemaNice.sobretituloSecao(grande: grande)),
                SizedBox(height: grande ? 10 : 6),
              ],
              Text(titulo.toUpperCase(), style: TemaNice.tituloSecao(grande: grande, pequeno: !kIsWeb)),
            ],
          ),
        ),
        if (aoAgir != null)
          TextButton.icon(
            onPressed: aoAgir,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_outward, size: 16),
            label: Text(textoAcao.toUpperCase()),
          ),
      ],
    );
  }
}
