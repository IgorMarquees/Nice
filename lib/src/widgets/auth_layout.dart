import 'package:flutter/material.dart';

import '../config/assets.dart';
import '../theme/nice_theme.dart';
import 'nice_logo.dart';
import 'responsive.dart';

/// Moldura das telas de login/cadastro: foto de fundo
/// (fundo_tela_login_e_cadastro.png) e o formulário num cartão branco.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;

    return Scaffold(
      backgroundColor: NiceTheme.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(NiceAssets.authBackground, fit: BoxFit.cover, cacheWidth: compact ? 1080 : 2048),
          const ColoredBox(color: NiceTheme.scrim),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 32, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: NiceLogo(light: true)),
                      const SizedBox(height: 24),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: NiceTheme.white,
                          borderRadius: BorderRadius.circular(NiceTheme.radius * 2),
                          boxShadow: NiceTheme.softShadow,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(compact ? 24 : 40),
                          child: child,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
