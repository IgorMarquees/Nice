import 'package:flutter/material.dart';

import '../theme/nice_theme.dart';
import '../widgets/responsive.dart';
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

  static const _appFooterHeight = 120.0;

  @override
  Widget build(BuildContext context) {
    // Na moldura Web a página termina com o rodapé do site.
    final web = context.findAncestorWidgetOfExactType<WebShell>() != null;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: PageViewport(
          height: constraints.maxHeight,
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
                  // Ocupa o resto da tela para o degradê ficar sempre no fim.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - _appFooterHeight).clamp(0, double.infinity),
                    ),
                    child: child,
                  ),
                if (web) const WebFooter(),
                // No app não há rodapé de site: a página termina num degradê cinza.
                if (!web)
                  const SizedBox(
                    height: _appFooterHeight,
                    child: DecoratedBox(decoration: BoxDecoration(gradient: NiceTheme.appFooterFade)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
