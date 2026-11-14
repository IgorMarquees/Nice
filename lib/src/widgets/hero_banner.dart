import 'package:flutter/material.dart';

import '../theme/nice_theme.dart';
import 'responsive.dart';

class HeroBanner extends StatelessWidget {
  const HeroBanner({
    super.key,
    required this.image,
    required this.eyebrow,
    required this.title,
    required this.accent,
    required this.subtitle,
    this.ctaLabel,
    this.onCta,
    this.height,
    this.large = true,
    this.imageAlignment = Alignment.centerRight,
  });

  final String image;
  final String eyebrow;
  final String title;
  final String accent;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final double? height;

  /// false = título menor (banners secundários).
  final bool large;
  final Alignment imageAlignment;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final desktop = context.isDesktop;
    final base = large
        ? (desktop ? text.displayLarge : text.displaySmall)
        : (desktop ? text.displayMedium : text.headlineLarge);
    final titleStyle = base!.copyWith(color: NiceTheme.white);

    return SizedBox(
      height: height ?? (desktop ? 560 : 360),
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(image, fit: BoxFit.cover, alignment: imageAlignment),
          const DecoratedBox(decoration: BoxDecoration(gradient: NiceTheme.heroOverlay)),
          ContentWrapper(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(eyebrow.toUpperCase(), style: text.labelMedium),
                    const SizedBox(height: 14),
                    Text.rich(
                      TextSpan(
                        text: '${title.toUpperCase()}\n',
                        style: titleStyle,
                        children: [
                          TextSpan(
                            text: accent.toUpperCase(),
                            style: titleStyle.copyWith(color: NiceTheme.brightRed),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      subtitle,
                      style: text.bodyLarge?.copyWith(color: NiceTheme.softGray),
                    ),
                    if (ctaLabel != null) ...[
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: onCta,
                        icon: const Icon(Icons.arrow_outward, size: 18),
                        label: Text(ctaLabel!.toUpperCase()),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
