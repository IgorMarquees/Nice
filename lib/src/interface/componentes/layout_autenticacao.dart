// Moldura das telas de login e cadastro.

import 'package:flutter/material.dart';

import '../../nucleo/imagens.dart';
import '../../nucleo/tema.dart';
import 'logo_nice.dart';
import 'responsivo.dart';

/// Foto de fundo com o formulário dentro de um cartão branco.
class LayoutAutenticacao extends StatelessWidget {
  const LayoutAutenticacao({super.key, required this.conteudo});

  final Widget conteudo;

  @override
  Widget build(BuildContext context) {
    final celular = context.ehCelular;

    return Scaffold(
      backgroundColor: TemaNice.preto,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(ImagensNice.fundoLogin, fit: BoxFit.cover, cacheWidth: celular ? 1080 : 2048),
          const ColoredBox(color: TemaNice.veu),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: celular ? 16 : 32, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: LogoNice(claro: true)),
                      const SizedBox(height: 24),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: TemaNice.branco,
                          borderRadius: BorderRadius.circular(TemaNice.raio * 2),
                          boxShadow: TemaNice.sombraSuave,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(celular ? 24 : 40),
                          child: conteudo,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
