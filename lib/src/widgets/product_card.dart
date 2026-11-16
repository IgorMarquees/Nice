import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/cart_controller.dart';
import '../models/product.dart';
import '../theme/nice_theme.dart';
import '../utils/feedback.dart';
import '../utils/navigation.dart';
import 'nice_network_image.dart';
import 'price_tag.dart';

/// Card editorial: foto grande, nome em vermelho, subtítulo e preço.
/// A altura é a natural do conteúdo (a grade não força proporção).
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  /// Proporção (largura / altura) da foto.
  static const imageRatio = 0.95;

  @override
  Widget build(BuildContext context) {
    final badge = !product.inStock ? 'Esgotado' : (product.isNew ? 'Novo' : null);

    return LayoutBuilder(
      builder: (context, constraints) {
        final large = constraints.maxWidth >= 260;
        return InkWell(
          onTap: () => context.push('/produto/${product.id}'),
          borderRadius: BorderRadius.circular(NiceTheme.radius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: imageRatio,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(NiceTheme.radius),
                        child: ColoredBox(
                          color: NiceTheme.softGray,
                          child: NiceNetworkImage(url: product.imageUrl),
                        ),
                      ),
                    ),
                    if (badge != null)
                      Positioned(left: 8, top: 8, child: TagBadge(label: badge, dark: !product.inStock)),
                    if (product.hasDiscount)
                      Positioned(right: 8, top: 8, child: DiscountBadge(percent: product.activeDiscountPercent)),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Material(
                        shape: const CircleBorder(),
                        color: NiceTheme.charcoal,
                        child: IconButton(
                          tooltip: 'Adicionar ao carrinho',
                          color: NiceTheme.white,
                          icon: const Icon(Icons.add_shopping_cart),
                          onPressed: () => _quickAdd(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: large ? 12 : 8),
              Text(
                product.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: NiceTheme.productName(large: large),
              ),
              const SizedBox(height: 2),
              Text(
                product.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: NiceTheme.productSubtitle(large: large),
              ),
              SizedBox(height: large ? 8 : 4),
              PriceTag(product: product),
            ],
          ),
        );
      },
    );
  }

  void _quickAdd(BuildContext context) {
    // Visitante é enviado ao login.
    if (!context.requireLogin()) return;

    if (!product.inStock) {
      showMessage(context, 'Produto esgotado.');
      return;
    }
    // Com mais de uma opção, o cliente escolhe na página do produto.
    if (product.sizes.length > 1 || product.colors.length > 1) {
      context.push('/produto/${product.id}');
      return;
    }
    final variant = [
      if (product.sizes.isNotEmpty) product.sizes.first,
      if (product.colors.isNotEmpty) product.colors.first,
    ].join(' / ');
    context.read<CartController>().add(product, size: variant);
    showAddedToCart(context, product.title);
  }
}
