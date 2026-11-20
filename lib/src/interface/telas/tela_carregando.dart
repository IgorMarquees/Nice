// Tela mostrada enquanto o app confere se havia alguém logado.

import 'package:flutter/material.dart';

import '../componentes/logo_nice.dart';

class TelaCarregando extends StatelessWidget {
  const TelaCarregando({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LogoNice(),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
