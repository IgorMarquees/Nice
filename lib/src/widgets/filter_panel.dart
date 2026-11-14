import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/catalog_controller.dart';
import '../theme/nice_theme.dart';
import '../utils/formatters.dart';

/// Filtros do catálogo: categoria, tamanho, preço máximo e ordenação.
/// Usado na barra lateral (Web) e na gaveta (mobile).
class FilterPanel extends StatelessWidget {
  const FilterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CATEGORIA', style: text.labelMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final category in CatalogController.categories)
              ChoiceChip(
                label: Text(category),
                selected: catalog.selectedCategory == category,
                labelStyle: NiceTheme.chipLabel(selected: catalog.selectedCategory == category),
                onSelected: (_) => catalog.setCategory(category),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('TAMANHO', style: text.labelMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final size in CatalogController.sizes)
              ChoiceChip(
                label: Text(size),
                selected: catalog.selectedSize == size,
                labelStyle: NiceTheme.chipLabel(selected: catalog.selectedSize == size),
                onSelected: (selected) => catalog.setSize(selected ? size : null),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('PREÇO MÁXIMO', style: text.labelMedium),
        Slider(
          value: catalog.maxPrice.clamp(0, catalog.highestPrice).toDouble(),
          min: 0,
          max: catalog.highestPrice,
          divisions: (catalog.highestPrice / 10).round().clamp(1, 100),
          onChanged: catalog.setMaxPrice,
        ),
        Text('Até ${formatCurrency(catalog.maxPrice)}', style: text.bodySmall),
        const SizedBox(height: 24),
        Text('ORDENAR POR', style: text.labelMedium),
        const SizedBox(height: 10),
        DropdownButtonFormField<SortOption>(
          key: ValueKey(catalog.sort),
          initialValue: catalog.sort,
          items: [
            for (final option in SortOption.values)
              DropdownMenuItem(value: option, child: Text(option.label)),
          ],
          onChanged: (value) {
            if (value != null) catalog.setSort(value);
          },
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: catalog.clearFilters,
            child: const Text('Limpar filtros'),
          ),
        ),
      ],
    );
  }
}
