// Item do carrinho e dos pedidos.

import 'produto.dart';

/// Uma peça no carrinho com uma cópia do nome foto e preço.
/// Assim o carrinho continua certo mesmo se o produto mudar depois.
class ItemCarrinho {
  const ItemCarrinho({
    required this.idProduto,
    required this.titulo,
    required this.urlFoto,
    required this.precoUnitario,
    required this.tamanho,
    required this.quantidade,
  });

  final String idProduto;
  final String titulo;
  final String urlFoto;
  final double precoUnitario;
  /// Variação escolhida com tamanho e cor juntos.
  final String tamanho;
  final int quantidade;

  /// Chave que identifica o item pelo produto e pela variação.
  String get chave => '$idProduto|$tamanho';
  /// Preço do item vezes a quantidade.
  double get subtotal => precoUnitario * quantidade;

  /// Cria o item a partir de um produto usando o preço com desconto.
  factory ItemCarrinho.doProduto(Produto produto, {required String tamanho, int quantidade = 1}) {
    return ItemCarrinho(
      idProduto: produto.id,
      titulo: produto.titulo,
      urlFoto: produto.urlFoto,
      precoUnitario: produto.precoFinal,
      tamanho: tamanho,
      quantidade: quantidade,
    );
  }

  ItemCarrinho copiarCom({int? quantidade}) => ItemCarrinho(
        idProduto: idProduto,
        titulo: titulo,
        urlFoto: urlFoto,
        precoUnitario: precoUnitario,
        tamanho: tamanho,
        quantidade: quantidade ?? this.quantidade,
      );

  /// Lê um item que veio do banco.
  factory ItemCarrinho.doMapa(Map<String, dynamic> mapa) {
    return ItemCarrinho(
      idProduto: mapa['product_id'].toString(),
      titulo: (mapa['title'] as String?) ?? '',
      urlFoto: (mapa['image_url'] as String?) ?? '',
      precoUnitario: (mapa['unit_price'] as num).toDouble(),
      tamanho: (mapa['size'] as String?) ?? '',
      quantidade: (mapa['quantity'] as num).toInt(),
    );
  }

  /// Formato de uma linha da tabela cart_items.
  Map<String, dynamic> paraLinha(String idUsuario) => {
        'user_id': idUsuario,
        'product_id': idProduto,
        'size': tamanho,
        'quantity': quantidade,
        'title': titulo,
        'unit_price': precoUnitario,
        'image_url': urlFoto,
      };

  /// Formato salvo dentro do pedido.
  Map<String, dynamic> paraMapaPedido() => {
        'product_id': idProduto,
        'title': titulo,
        'image_url': urlFoto,
        'unit_price': precoUnitario,
        'size': tamanho,
        'quantity': quantidade,
        'subtotal': subtotal,
      };
}
