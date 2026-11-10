import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../favorites/favorites_controller.dart';
import '../widgets/nice_logo.dart';
import '../widgets/product_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesController>();

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 14),
          const NiceLogo(compact: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
            child: Row(
              children: [
                Text('Favoritos', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const Spacer(),
                TextButton(onPressed: favorites.items.isEmpty ? null : favorites.clear, child: const Text('Limpar')),
              ],
            ),
          ),
          Expanded(
            child: favorites.items.isEmpty
                ? const Center(child: Text('Nenhum favorito ainda.'))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: favorites.items.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 18,
                      childAspectRatio: 0.58,
                    ),
                    itemBuilder: (context, index) => ProductCard(product: favorites.items[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
