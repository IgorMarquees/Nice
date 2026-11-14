import 'package:flutter/material.dart';

import '../config/assets.dart';
import '../theme/nice_theme.dart';
import 'nice_logo.dart';
import 'responsive.dart';

/// Moldura das telas de login/cadastro.
/// Web (desktop): imagem editorial à esquerda e formulário à direita.
/// Mobile: banner no topo e formulário abaixo.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    if (context.isDesktop) {
      final titleStyle = text.displaySmall?.copyWith(color: NiceTheme.white);
      return Scaffold(
        body: Row(
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(NiceAssets.loginSide, fit: BoxFit.cover),
                  const DecoratedBox(decoration: BoxDecoration(gradient: NiceTheme.bottomOverlay)),
                  Positioned(
                    left: 56,
                    right: 56,
                    bottom: 64,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const NiceLogo(light: true),
                        const SizedBox(height: 24),
                        Text.rich(
                          TextSpan(
                            style: titleStyle,
                            children: [
                              const TextSpan(text: 'YOUR STYLE'),
                              TextSpan(text: '.\n', style: titleStyle?.copyWith(color: NiceTheme.brightRed)),
                              const TextSpan(text: 'YOUR IDENTITY'),
                              TextSpan(text: '.', style: titleStyle?.copyWith(color: NiceTheme.brightRed)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(48),
                  child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: child),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 230,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(NiceAssets.loginSide, fit: BoxFit.cover, alignment: Alignment.topCenter),
                  const DecoratedBox(decoration: BoxDecoration(gradient: NiceTheme.bottomOverlay)),
                  const SafeArea(bottom: false, child: Center(child: NiceLogo(light: true))),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(context.pagePadding + 4, 28, context.pagePadding + 4, 32),
              child: Center(
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
