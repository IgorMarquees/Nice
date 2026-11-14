import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/cart_controller.dart';
import '../models/product.dart';
import '../theme/nice_theme.dart';
import '../utils/formatters.dart';
import '../utils/navigation.dart';
import 'nice_network_image.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final badge = !product.inStock ? 'Esgotado' : (product.isNew ? 'Novo' : null);

    return InkWell(
      onTap: () => context.push('/produto/${product.id}'),
      borderRadius: BorderRadius.circular(NiceTheme.radius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
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
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: product.inStock ? NiceTheme.red : NiceTheme.charcoal,
                      child: Text(
                        badge.toUpperCase(),
                        style: text.labelSmall?.copyWith(color: NiceTheme.white),
                      ),
                    ),
                  ),
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
          const SizedBox(height: 10),
          Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleMedium),
          const SizedBox(height: 2),
          Text(product.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
          const SizedBox(height: 4),
          Text(formatCurrency(product.price), style: text.titleSmall),
        ],
      ),
    );
  }

  void _quickAdd(BuildContext context) {
    // Visitante é enviado ao login.
    if (!context.requireLogin()) return;

    final messenger = ScaffoldMessenger.of(context);
    if (!product.inStock) {
      messenger.showSnackBar(const SnackBar(content: Text('Produto esgotado.')));
      return;
    }
    // Com mais de um tamanho, o cliente precisa escolher na página do produto.
    if (product.sizes.length > 1) {
      context.push('/produto/${product.id}');
      return;
    }
    context.read<CartController>().add(
          product,
          size: product.sizes.isEmpty ? '' : product.sizes.first,
        );
    messenger.showSnackBar(SnackBar(content: Text('${product.title} adicionado ao carrinho')));
  }
}
