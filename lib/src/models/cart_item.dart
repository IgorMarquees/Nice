import 'product.dart';

/// Item do carrinho com "snapshot" do produto (título, preço e foto),
/// o que permite exibir o carrinho mesmo se o produto for alterado/removido.
class CartItem {
  const CartItem({
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.unitPrice,
    required this.size,
    required this.quantity,
  });

  final String productId;
  final String title;
  final String imageUrl;
  final double unitPrice;
  final String size;
  final int quantity;

  String get key => '$productId|$size';
  double get subtotal => unitPrice * quantity;

  factory CartItem.fromProduct(Product product, {required String size, int quantity = 1}) {
    return CartItem(
      productId: product.id,
      title: product.title,
      imageUrl: product.imageUrl,
      unitPrice: product.price,
      size: size,
      quantity: quantity,
    );
  }

  CartItem copyWith({int? quantity}) => CartItem(
        productId: productId,
        title: title,
        imageUrl: imageUrl,
        unitPrice: unitPrice,
        size: size,
        quantity: quantity ?? this.quantity,
      );

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['product_id'].toString(),
      title: (map['title'] as String?) ?? '',
      imageUrl: (map['image_url'] as String?) ?? '',
      unitPrice: (map['unit_price'] as num).toDouble(),
      size: (map['size'] as String?) ?? '',
      quantity: (map['quantity'] as num).toInt(),
    );
  }

  /// Linha da tabela `cart_items`.
  Map<String, dynamic> toRow(String userId) => {
        'user_id': userId,
        'product_id': productId,
        'size': size,
        'quantity': quantity,
        'title': title,
        'unit_price': unitPrice,
        'image_url': imageUrl,
      };

  /// Formato salvo dentro de `orders.items` (jsonb).
  Map<String, dynamic> toOrderMap() => {
        'product_id': productId,
        'title': title,
        'image_url': imageUrl,
        'unit_price': unitPrice,
        'size': size,
        'quantity': quantity,
        'subtotal': subtotal,
      };
}
