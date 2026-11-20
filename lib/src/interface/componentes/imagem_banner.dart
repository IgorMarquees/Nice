import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'responsivo.dart';

/// Mostra a arte sem cortar o texto e vira link quando recebe uma ação.
/// No topo das páginas a altura nunca passa da parte visível da tela.
class ImagemBanner extends StatelessWidget {
  const ImagemBanner({
    super.key,
    required this.arte,
    required this.proporcao,
    this.aoTocar,
    this.rotulo,
    this.caberNaTela = false,
    this.proporcaoApp,
  });

  final String arte;

  final double proporcao;
  final VoidCallback? aoTocar;

  final String? rotulo;
  final bool caberNaTela;

  /// Proporção mais alta usada no celular para o texto da arte ficar legível.
  final double? proporcaoApp;

  /// Só usa a proporção do celular no app e em tela de celular.
  static bool _usarApp(BuildContext context, double? proporcaoApp) =>
      !kIsWeb && proporcaoApp != null && context.ehCelular;

  static double alturaPara(
    BuildContext context,
    double largura,
    double proporcao, {
    required bool caberNaTela,
    double? proporcaoApp,
  }) {
    if (_usarApp(context, proporcaoApp)) return largura / proporcaoApp!;
    final natural = largura / proporcao;
    if (!caberNaTela) return natural;
    final visivel = AlturaVisivel.daArvore(context) ?? MediaQuery.sizeOf(context).height;
    return natural > visivel ? visivel : natural;
  }

  @override
  Widget build(BuildContext context) {
    final imagem = LayoutBuilder(
      builder: (context, limites) {
        final largura = limites.maxWidth;
        final recortado = _usarApp(context, proporcaoApp);
        final altura = alturaPara(context, largura, proporcao, caberNaTela: caberNaTela, proporcaoApp: proporcaoApp);
        final densidade = MediaQuery.devicePixelRatioOf(context);
        final larguraCache = (((largura * densidade) / 480).ceil() * 480).clamp(480, 2880);

        Widget foto({BoxFit ajuste = BoxFit.cover}) => Image.asset(
          arte,
          fit: ajuste,
          alignment: recortado ? Alignment.centerLeft : Alignment.center,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: recortado ? (larguraCache * proporcao / proporcaoApp!).round().clamp(480, 2880) : larguraCache,
          gaplessPlayback: true,
        );

        final comFaixas = !recortado && altura < largura / proporcao - 0.5;
        return SizedBox(
          width: largura,
          height: altura,
          child: !comFaixas
              ? foto()
              : ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Transform.scale(
                        scale: 1.3,
                        child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40), child: foto()),
                      ),
                      Center(
                        child: AspectRatio(aspectRatio: proporcao, child: foto()),
                      ),
                    ],
                  ),
                ),
        );
      },
    );

    if (aoTocar == null) return Semantics(image: true, label: rotulo, child: imagem);
    return Semantics(
      link: true,
      label: rotulo,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: aoTocar, child: imagem),
      ),
    );
  }
}
