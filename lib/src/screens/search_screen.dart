import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalog/catalog_controller.dart';
import '../theme/nice_theme.dart';
import '../widgets/nice_logo.dart';
import '../widgets/product_card.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 14),
          const NiceLogo(compact: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
            child: Row(
              children: [
                Expanded(
                  child: Text('O que voce procura hoje?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                ),
                const Icon(Icons.tune, color: NiceTheme.red),
                const SizedBox(width: 18),
                const Icon(Icons.search, color: NiceTheme.red),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: catalog.categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final category = catalog.categories[index];
                final selected = category == catalog.selectedCategory;
                return ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  selectedColor: NiceTheme.red,
                  labelStyle: TextStyle(color: selected ? Colors.white : NiceTheme.textGray, fontWeight: FontWeight.w700),
                  onSelected: (_) => catalog.setCategory(category),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              itemCount: catalog.products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 24,
                crossAxisSpacing: 18,
                childAspectRatio: 0.58,
              ),
              itemBuilder: (context, index) => ProductCard(product: catalog.products[index]),
            ),
          ),
        ],
      ),
    );
  }
}
