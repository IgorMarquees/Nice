import 'package:flutter/material.dart';

import '../theme/nice_theme.dart';

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isDesktop => screenWidth >= NiceTheme.desktopBreakpoint;
  bool get isTablet => screenWidth >= NiceTheme.tabletBreakpoint && !isDesktop;
  bool get isCompact => screenWidth < NiceTheme.tabletBreakpoint;
  double get pagePadding => isDesktop ? 48 : (isTablet ? 32 : 20);
}

/// Centraliza o conteúdo com largura máxima (layout de site na Web).
class ContentWrapper extends StatelessWidget {
  const ContentWrapper({
    super.key,
    required this.child,
    this.maxWidth = NiceTheme.maxContentWidth,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(horizontal: context.pagePadding),
          child: child,
        ),
      ),
    );
  }
}
