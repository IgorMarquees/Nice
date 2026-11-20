// Card de produto usado nas grades e carrosséis.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controladores/controlador_carrinho.dart';
import '../../dados/produto.dart';
import '../../nucleo/tema.dart';
import '../../nucleo/avisos.dart';
import '../../nucleo/navegacao.dart';
import 'imagem_rede.dart';
import 'etiqueta_preco.dart';

/// Foto nome descrição preço e botão rápido de carrinho.
class CartaoProduto extends StatelessWidget {
  const CartaoProduto({super.key, required this.produto});

  final Produto produto;

  /// Proporção da foto do card.
  static const proporcaoFoto = 0.95;

  @override
  Widget build(BuildContext context) {
    final selo = !produto.temEstoque ? 'Esgotado' : (produto.novidade ? 'Novo' : null);

    return LayoutBuilder(
      builder: (context, limites) {
        final grande = limites.maxWidth >= 260;
        return InkWell(
          onTap: () => context.push('/produto/${produto.id}'),
          borderRadius: BorderRadius.circular(TemaNice.raio),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: proporcaoFoto,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(TemaNice.raio),
                        child: ColoredBox(
                          color: TemaNice.cinzaSuave,
                          child: ImagemRede(url: produto.urlFoto),
                        ),
                      ),
                    ),
                    if (selo != null)
                      Positioned(left: 8, top: 8, child: SeloTexto(rotulo: selo, escuro: !produto.temEstoque)),
                    if (produto.temDesconto)
                      Positioned(right: 8, top: 8, child: SeloDesconto(percentual: produto.percentualDescontoAtivo)),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Material(
                        shape: const CircleBorder(),
                        color: TemaNice.grafite,
                        child: IconButton(
                          tooltip: 'Adicionar ao carrinho',
                          color: TemaNice.branco,
                          icon: const Icon(Icons.add_shopping_cart),
                          onPressed: () => _adicionarRapido(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: grande ? 12 : 8),
              Text(
                produto.titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TemaNice.nomeProduto(grande: grande),
              ),
              const SizedBox(height: 2),
              Text(
                produto.descricao,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TemaNice.subtituloProduto(grande: grande),
              ),
              SizedBox(height: grande ? 8 : 4),
              EtiquetaPreco(produto: produto),
            ],
          ),
        );
      },
    );
  }

  /// Adiciona direto ao carrinho.
  /// Se o produto tiver mais de uma opção abre a página dele.
  void _adicionarRapido(BuildContext context) {
    if (!context.exigirLogin()) return;

    if (!produto.temEstoque) {
      mostrarMensagem(context, 'Produto esgotado.');
      return;
    }
    if (produto.tamanhos.length > 1 || produto.cores.length > 1) {
      context.push('/produto/${produto.id}');
      return;
    }
    final variante = [
      if (produto.tamanhos.isNotEmpty) produto.tamanhos.first,
      if (produto.cores.isNotEmpty) produto.cores.first,
    ].join(' / ');
    context.read<ControladorCarrinho>().adicionar(produto, tamanho: variante);
    avisarAdicionadoAoCarrinho(context, produto.titulo);
  }
}
