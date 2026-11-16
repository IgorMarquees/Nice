import 'dart:math';

import 'package:flutter/material.dart';

import '../models/product.dart';
import 'product_card.dart';

/// Quantas colunas cabem na largura disponível.
int productColumns(double width, {int maxColumns = 4}) =>
    min(maxColumns, width >= 900 ? 4 : (width >= 600 ? 3 : 2));

/// Grade responsiva: 2 colunas no celular, 3 no tablet, até [maxColumns] no desktop.
/// Monta linhas de cards com altura natural (sem proporção fixa), então o
/// texto nunca estoura, seja qual for a largura.
class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.products, this.maxColumns = 4});

  final List<Product> products;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = productColumns(constraints.maxWidth, maxColumns: maxColumns);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var start = 0; start < products.length; start += columns) ...[
              if (start > 0) const SizedBox(height: 32),
              ProductRow(products: products.skip(start).take(columns).toList(), columns: columns),
            ],
          ],
        );
      },
    );
  }
}

/// Uma linha com [columns] posições (as que sobram ficam vazias).
class ProductRow extends StatelessWidget {
  const ProductRow({super.key, required this.products, required this.columns, this.gap = 20});

  final List<Product> products;
  final int columns;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < columns; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: i < products.length ? ProductCard(product: products[i]) : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}
