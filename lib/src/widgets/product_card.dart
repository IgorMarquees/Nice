import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../cart/cart_controller.dart';
import '../catalog/product.dart';
import '../favorites/favorites_controller.dart';
import '../theme/nice_theme.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
  });

  final Product product;

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesController>();
    final liked = favorites.contains(product);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  color: NiceTheme.softGray,
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(Icons.checkroom, size: 52),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Material(
                  shape: const CircleBorder(),
                  color: Colors.white,
                  child: IconButton(
                    tooltip: liked ? 'Remover dos favoritos' : 'Favoritar',
                    icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: NiceTheme.red),
                    onPressed: () => favorites.toggle(product),
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
                    icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                    onPressed: () {
                      context.read<CartController>().add(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${product.title} adicionado ao carrinho')),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          product.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: NiceTheme.red,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          product.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: NiceTheme.red, fontSize: 10),
        ),
        Text(
          _currency(product.price),
          style: const TextStyle(color: NiceTheme.red, fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  String _currency(double value) => 'R\$${value.toStringAsFixed(2).replaceAll('.', ',')}';
}
