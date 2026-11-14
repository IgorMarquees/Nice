import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';

extension NiceNavigation on BuildContext {
  /// Retorna true se há usuário logado. Caso contrário, redireciona para o
  /// login (voltando para a tela atual depois) e retorna false.
  bool requireLogin() {
    final auth = Provider.of<AuthController>(this, listen: false);
    if (auth.isSignedIn) return true;
    final from = GoRouterState.of(this).uri.toString();
    go('/login?from=${Uri.encodeComponent(from)}');
    return false;
  }

  void goBackOr(String fallback) => canPop() ? pop() : go(fallback);
}
