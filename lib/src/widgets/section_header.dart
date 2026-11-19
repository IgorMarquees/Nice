import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/nice_theme.dart';
import 'responsive.dart';

/// Cabeçalho editorial: "Destaques" em vermelho e título fino em caixa alta.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.actionLabel = 'Veja tudo',
    this.onAction,
  });

  final String title;
  final String? eyebrow;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final large = context.isDesktop;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(eyebrow!, style: NiceTheme.sectionEyebrow(large: large)),
                SizedBox(height: large ? 10 : 6),
              ],
              // No app o título é um pouco menor ("Escolhas do momento", "Peças que acabaram de chegar").
              Text(title.toUpperCase(), style: NiceTheme.sectionTitle(large: large, small: !kIsWeb)),
            ],
          ),
        ),
        if (onAction != null)
          TextButton.icon(
            onPressed: onAction,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_outward, size: 16),
            label: Text(actionLabel.toUpperCase()),
          ),
      ],
    );
  }
}
