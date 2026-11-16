import 'package:flutter/material.dart';

import '../widgets/web_navbar.dart';

/// Estrutura do site (Web): cabeçalho fixo e a página atual abaixo.
/// A rolagem e o rodapé ficam em cada página ([ShellPage]).
class WebShell extends StatelessWidget {
  const WebShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: WebNavDrawer(location: location),
      body: Column(
        children: [
          WebNavbar(location: location),
          Expanded(child: child),
        ],
      ),
    );
  }
}
