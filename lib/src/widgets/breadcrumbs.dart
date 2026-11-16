import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/nice_theme.dart';

class Crumb {
  const Crumb(this.label, [this.path]);

  final String label;

  /// null = página atual (não clicável).
  final String? path;
}

/// Trilha de navegação: Home / Catálogo / Camisetas / Produto.
class Breadcrumbs extends StatelessWidget {
  const Breadcrumbs({super.key, required this.items});

  final List<Crumb> items;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final linkStyle = text.labelMedium;
    final currentStyle = text.labelMedium?.copyWith(color: NiceTheme.textGray);

    return Semantics(
      label: 'Navegação estrutural',
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 4,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.chevron_right, size: 16, color: NiceTheme.midGray),
              ),
            if (items[i].path == null)
              Text(items[i].label.toUpperCase(), style: currentStyle)
            else
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go(items[i].path!),
                  child: Text(items[i].label.toUpperCase(), style: linkStyle),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
