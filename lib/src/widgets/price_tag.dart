import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/nice_theme.dart';
import '../utils/formatters.dart';

/// Preço do produto: com desconto mostra o valor cheio riscado e,
/// à direita, o valor com desconto.
class PriceTag extends StatelessWidget {
  const PriceTag({super.key, required this.product, this.large = false});

  final Product product;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final current = Text(formatCurrency(product.finalPrice), style: NiceTheme.price(large: large));
    if (!product.hasDiscount) return current;

    return Wrap(
      spacing: large ? 12 : 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(formatCurrency(product.price), style: NiceTheme.oldPrice(large: large)),
        current,
      ],
    );
  }
}

/// Etiqueta "-20%" no canto superior direito da foto.
class DiscountBadge extends StatelessWidget {
  const DiscountBadge({super.key, required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: NiceTheme.brightRed,
        borderRadius: BorderRadius.circular(NiceTheme.radius / 2),
      ),
      child: Text('-$percent%', style: NiceTheme.badge()),
    );
  }
}

/// Selo simples ("NOVO", "ESGOTADO").
class TagBadge extends StatelessWidget {
  const TagBadge({super.key, required this.label, this.dark = false});

  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      color: dark ? NiceTheme.charcoal : NiceTheme.red,
      child: Text(label.toUpperCase(), style: NiceTheme.badge()),
    );
  }
}
