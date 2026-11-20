import 'package:flutter/material.dart';

import '../../nucleo/tema.dart';

class ImagemRede extends StatelessWidget {
  const ImagemRede({super.key, required this.url, this.ajuste = BoxFit.contain});

  final String url;
  final BoxFit ajuste;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const _SemImagem();
    return Image.network(
      url,
      fit: ajuste,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, conteudo, progresso) =>
          progresso == null ? conteudo : const _SemImagem(),
      errorBuilder: (_, _, _) => const _SemImagem(),
    );
  }
}

class _SemImagem extends StatelessWidget {
  const _SemImagem();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: TemaNice.cinzaSuave,
      child: Center(child: Icon(Icons.checkroom, size: 48, color: TemaNice.cinzaTexto)),
    );
  }
}
