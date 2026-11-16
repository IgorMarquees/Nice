import 'dart:math';

import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/nice_theme.dart';
import 'product_grid.dart';

/// Carrossel de produtos: no máximo 3 por "giro" (2 no tablet, 1 no celular).
/// Troca de página por setas, indicadores ou arrastando para os lados.
class ProductCarousel extends StatefulWidget {
  const ProductCarousel({super.key, required this.products, this.maxPerPage = 3});

  final List<Product> products;
  final int maxPerPage;

  @override
  State<ProductCarousel> createState() => _ProductCarouselState();
}

class _ProductCarouselState extends State<ProductCarousel> {
  int _page = 0;
  int _direction = 1;

  void _go(int page, int pageCount) {
    setState(() {
      _direction = page >= _page ? 1 : -1;
      _page = (page + pageCount) % pageCount; // gira em loop
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final perPage = min(widget.maxPerPage, width >= 900 ? 3 : (width >= 560 ? 2 : 1));
        final pageCount = max(1, (widget.products.length / perPage).ceil());
        final page = _page.clamp(0, pageCount - 1);
        final items = widget.products.skip(page * perPage).take(perPage).toList();
        final canMove = pageCount > 1;

        final slide = AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, ?current],
          ),
          transitionBuilder: (child, animation) {
            final incoming = child.key == ValueKey('$page-$perPage');
            final offset = Tween<Offset>(
              begin: Offset((incoming ? 1 : -1) * 0.25 * _direction, 0),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offset, child: child),
            );
          },
          child: ProductRow(
            key: ValueKey('$page-$perPage'),
            products: items,
            columns: perPage,
            gap: 24,
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: canMove
                  ? (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity < -150) _go(page + 1, pageCount);
                      if (velocity > 150) _go(page - 1, pageCount);
                    }
                  : null,
              child: slide,
            ),
            if (canMove) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.outlined(
                    tooltip: 'Anterior',
                    onPressed: () => _go(page - 1, pageCount),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  const SizedBox(width: 12),
                  for (var i = 0; i < pageCount; i++)
                    GestureDetector(
                      onTap: () => _go(i, pageCount),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                        width: i == page ? 32 : 14,
                        height: 3,
                        color: i == page ? NiceTheme.brightRed : NiceTheme.softGray,
                      ),
                    ),
                  const SizedBox(width: 12),
                  IconButton.outlined(
                    tooltip: 'Próximo',
                    onPressed: () => _go(page + 1, pageCount),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
