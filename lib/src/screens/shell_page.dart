import 'package:flutter/material.dart';

import '../widgets/web_footer.dart';
import 'web_shell.dart';

/// Rolagem de cada página dentro das molduras (Web e mobile).
///
/// A rolagem fica DENTRO da página, e não em volta do Navigator do
/// GoRouter: antes o Navigator (que tem GlobalKey) ficava dentro de um
/// SingleChildScrollView com `key: ValueKey(location)` num LayoutBuilder, e a
/// cada troca de rota era reparentado durante o layout — o que causava
/// "Duplicate GlobalKeys", "wrong build scope", `_dependents.isEmpty` e
/// overflows durante a transição de página.
class ShellPage extends StatelessWidget {
  const ShellPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Na moldura Web a página termina com o rodapé do site.
    final web = context.findAncestorWidgetOfExactType<WebShell>() != null;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (web)
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight * 0.6),
                  child: child,
                )
              else
                child,
              if (web) const WebFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
