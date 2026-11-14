import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../controllers/catalog_controller.dart';
import '../theme/nice_theme.dart';
import 'responsive.dart';

const _categoryIcons = <String, IconData>{
  'Camisetas': Icons.checkroom,
  'Moletons': Icons.dry_cleaning,
  'Calças': Icons.straighten,
  'Acessórios': Icons.watch_outlined,
};

void _openCategory(BuildContext context, String category) =>
    context.go('/catalogo?categoria=${Uri.encodeQueryComponent(category)}');

/// Mobile: chips rápidos. Desktop/Web: grade de blocos de categoria.
class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final names = CatalogController.categories.skip(1).toList();

    if (context.isCompact) {
      return SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: names.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) => ActionChip(
            avatar: Icon(_categoryIcons[names[index]], size: 18, color: NiceTheme.red),
            label: Text(names[index]),
            onPressed: () => _openCategory(context, names[index]),
          ),
        ),
      );
    }

    final columns = context.isDesktop ? 4 : 2;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: columns,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [for (final name in names) _CategoryTile(name: name)],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => _openCategory(context, name),
      borderRadius: BorderRadius.circular(NiceTheme.radius),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: NiceTheme.charcoal,
          borderRadius: BorderRadius.circular(NiceTheme.radius),
          gradient: NiceTheme.bottomOverlay,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(_categoryIcons[name], size: 40, color: NiceTheme.brightRed),
            Text(
              name.toUpperCase(),
              style: text.headlineSmall?.copyWith(color: NiceTheme.white),
            ),
          ],
        ),
      ),
    );
  }
}
