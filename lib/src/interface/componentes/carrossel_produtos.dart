import 'dart:math';

import 'package:flutter/material.dart';

import '../../dados/produto.dart';
import '../../nucleo/tema.dart';
import 'grade_produtos.dart';

class CarrosselProdutos extends StatefulWidget {
  const CarrosselProdutos({super.key, required this.produtos, this.maxPorPagina = 3});

  final List<Produto> produtos;
  final int maxPorPagina;

  @override
  State<CarrosselProdutos> createState() => _CarrosselProdutosEstado();
}

class _CarrosselProdutosEstado extends State<CarrosselProdutos> {
  int _pagina = 0;
  int _direcao = 1;

  /// Vai para outra página e volta ao começo depois da última.
  void _irPara(int pagina, int totalPaginas) {
    setState(() {
      _direcao = pagina >= _pagina ? 1 : -1;
      _pagina = (pagina + totalPaginas) % totalPaginas;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, limites) {
        final largura = limites.maxWidth;
        final porPagina = min(widget.maxPorPagina, largura >= 900 ? 3 : (largura >= 560 ? 2 : 1));
        final totalPaginas = max(1, (widget.produtos.length / porPagina).ceil());
        final pagina = _pagina.clamp(0, totalPaginas - 1);
        final itens = widget.produtos.skip(pagina * porPagina).take(porPagina).toList();
        final podeGirar = totalPaginas > 1;

        final slide = AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (atual, anterior) => Stack(
            alignment: Alignment.topCenter,
            children: [...anterior, ?atual],
          ),
          transitionBuilder: (conteudo, animacao) {
            final entrando = conteudo.key == ValueKey('$pagina-$porPagina');
            final deslocamento = Tween<Offset>(
              begin: Offset((entrando ? 1 : -1) * 0.25 * _direcao, 0),
              end: Offset.zero,
            ).animate(animacao);
            return FadeTransition(
              opacity: animacao,
              child: SlideTransition(position: deslocamento, child: conteudo),
            );
          },
          child: LinhaProdutos(
            key: ValueKey('$pagina-$porPagina'),
            produtos: itens,
            colunas: porPagina,
            espaco: 24,
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: podeGirar
                  ? (detalhes) {
                      final velocidade = detalhes.primaryVelocity ?? 0;
                      if (velocidade < -150) _irPara(pagina + 1, totalPaginas);
                      if (velocidade > 150) _irPara(pagina - 1, totalPaginas);
                    }
                  : null,
              child: slide,
            ),
            if (podeGirar) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.outlined(
                    tooltip: 'Anterior',
                    onPressed: () => _irPara(pagina - 1, totalPaginas),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  const SizedBox(width: 12),
                  for (var i = 0; i < totalPaginas; i++)
                    GestureDetector(
                      onTap: () => _irPara(i, totalPaginas),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                        width: i == pagina ? 32 : 14,
                        height: 3,
                        color: i == pagina ? TemaNice.vermelhoVivo : TemaNice.cinzaSuave,
                      ),
                    ),
                  const SizedBox(width: 12),
                  IconButton.outlined(
                    tooltip: 'Próximo',
                    onPressed: () => _irPara(pagina + 1, totalPaginas),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
