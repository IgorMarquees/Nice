import 'package:flutter/material.dart';

import '../config/assets.dart';

class NiceLogo extends StatelessWidget {
  const NiceLogo({super.key, this.compact = false, this.light = false});

  final bool compact;

  /// true = logo branca (para fundos escuros); false = logo escura.
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      light ? NiceAssets.logoLight : NiceAssets.logoDark,
      height: compact ? 44 : 96,
      fit: BoxFit.contain,
    );
  }
}
