import 'dart:math';

import 'package:flutter/material.dart';

import '../models/product.dart';
import 'product_card.dart';

/// Grade responsiva: 2 colunas no celular, 3 no tablet, até [maxColumns] no desktop.
class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.products, this.maxColumns = 4});

  final List<Product> products;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = min(maxColumns, width >= 900 ? 4 : (width >= 600 ? 3 : 2));
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 24,
            crossAxisSpacing: 18,
            childAspectRatio: columns >= 3 ? 0.62 : 0.58,
          ),
          itemBuilder: (context, index) => ProductCard(product: products[index]),
        );
      },
    );
  }
}
