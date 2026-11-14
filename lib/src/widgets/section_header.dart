import 'package:flutter/material.dart';

import 'responsive.dart';

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
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(eyebrow!.toUpperCase(), style: text.labelMedium),
                const SizedBox(height: 6),
              ],
              Text(
                title.toUpperCase(),
                style: context.isDesktop ? text.displaySmall : text.headlineMedium,
              ),
            ],
          ),
        ),
        if (onAction != null) TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}
