// Carrossel de banners da Home.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../nucleo/tema.dart';
import 'imagem_banner.dart';

/// Um banner do carrossel e a página que ele abre.
class SlideBanner {
  const SlideBanner({required this.imagem, required this.proporcao, required this.rota, required this.rotulo});

  final String imagem;
  final double proporcao;
  final String rota;
  final String rotulo;
}

/// Banners que trocam sozinhos a cada seis segundos.
class CarrosselBanners extends StatefulWidget {
  const CarrosselBanners({super.key, required this.slides, this.proporcaoApp});

  final List<SlideBanner> slides;

  /// Proporção mais alta usada só no celular.
  final double? proporcaoApp;

  @override
  State<CarrosselBanners> createState() => _CarrosselBannersEstado();
}

/// Guarda a página atual e o temporizador da troca automática.
class _CarrosselBannersEstado extends State<CarrosselBanners> {
  final _controlador = PageController();
  Timer? _temporizador;
  int _pagina = 0;

  /// Liga o temporizador que avança o carrossel.
  @override
  void initState() {
    super.initState();
    _temporizador = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!_controlador.hasClients || widget.slides.length < 2) return;
      final proxima = (_pagina + 1) % widget.slides.length;
      _controlador.animateToPage(proxima, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }

  /// Desliga o temporizador quando a tela fecha.
  @override
  void dispose() {
    _temporizador?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formato = widget.slides.first.proporcao;

    return LayoutBuilder(
      builder: (context, limites) => SizedBox(
        height: ImagemBanner.alturaPara(
          context,
          limites.maxWidth,
          formato,
          caberNaTela: true,
          proporcaoApp: widget.proporcaoApp,
        ),
        child: _pilha(formato),
      ),
    );
  }

  /// Banners e os indicadores de página por cima.
  Widget _pilha(double formato) {
    return Stack(
      children: [
        PageView.builder(
          controller: _controlador,
          itemCount: widget.slides.length,
          onPageChanged: (indice) => setState(() => _pagina = indice),
          itemBuilder: (context, indice) {
            final slide = widget.slides[indice];
            return ImagemBanner(
              arte: slide.imagem,
              proporcao: formato,
              rotulo: slide.rotulo,
              caberNaTela: true,
              proporcaoApp: widget.proporcaoApp,
              aoTocar: () => context.go(slide.rota),
            );
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 14,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.slides.length; i++)
                GestureDetector(
                  onTap: () => _controlador.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    width: i == _pagina ? 32 : 14,
                    height: 3,
                    color: i == _pagina ? TemaNice.vermelhoVivo : TemaNice.cinzaMedio,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
