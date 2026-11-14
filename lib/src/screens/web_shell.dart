import 'package:flutter/material.dart';

import '../widgets/web_footer.dart';
import '../widgets/web_navbar.dart';

/// Estrutura do site (Web): cabeçalho fixo, conteúdo rolável e rodapé.
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
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                key: ValueKey(location),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight * 0.6),
                      child: child,
                    ),
                    const WebFooter(),
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
