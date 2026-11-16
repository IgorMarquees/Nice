import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/catalog_controller.dart';
import '../theme/nice_theme.dart';
import '../utils/navigation.dart';
import 'nice_network_image.dart';
import 'responsive.dart';

const _categoryIcons = <String, IconData>{
  'Camisetas': Icons.checkroom,
  'Moletons': Icons.dry_cleaning,
  'Calças': Icons.straighten,
  'Acessórios': Icons.watch_outlined,
};

void openCategory(BuildContext context, String category) => context.go(catalogPath(category: category));

/// Mobile: chips rápidos. Web/tablet: uma linha de blocos com a foto de um
/// produto da categoria (as capas vêm do catálogo, não são imagens geradas).
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
            onPressed: () => openCategory(context, names[index]),
          ),
        ),
      );
    }

    final catalog = context.watch<CatalogController>();
    final columns = context.isDesktop ? 4 : 2;
    const ratio = 1.35;
    const large = false;

    final rows = <Widget>[];
    for (var start = 0; start < names.length; start += columns) {
      if (start > 0) rows.add(const SizedBox(height: 16));
      rows.add(
        Row(
          children: [
            for (var i = start; i < start + columns; i++) ...[
              if (i > start) const SizedBox(width: 16),
              Expanded(
                child: i < names.length
                    ? AspectRatio(
                        aspectRatio: ratio,
                        child: _CategoryTile(name: names[i], cover: catalog.coverFor(names[i]), large: large),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.name, required this.cover, required this.large});

  final String name;
  final String cover;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NiceTheme.charcoal,
      borderRadius: BorderRadius.circular(NiceTheme.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openCategory(context, name),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cover.isNotEmpty)
              NiceNetworkImage(url: cover, fit: BoxFit.cover)
            else
              Center(child: Icon(_categoryIcons[name], size: 56, color: NiceTheme.brightRed)),
            const DecoratedBox(decoration: BoxDecoration(gradient: NiceTheme.bottomOverlay)),
            Positioned(
              left: large ? 32 : 16,
              right: 16,
              bottom: large ? 28 : 14,
              child: Text(
                name.toUpperCase(),
                textAlign: large ? TextAlign.start : TextAlign.center,
                style: NiceTheme.categoryLabel(large: large),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
