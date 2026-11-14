import 'package:flutter/material.dart';

import '../widgets/nice_logo.dart';

/// Exibida enquanto a sessão salva é restaurada (ex.: F5 numa rota protegida).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NiceLogo(),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
