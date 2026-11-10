import 'package:flutter/material.dart';

class NiceLogo extends StatelessWidget {
  const NiceLogo({super.key, this.compact = false, this.light = false});

  final bool compact;

  /// true = logo branca (login e cadastro). false = logo escura (resto do app).
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      light ? 'assets/NiceB.PSD.png' : 'assets/NiceP.PSD.png',
      height: compact ? 44 : 96,
      fit: BoxFit.contain,
    );
  }
}