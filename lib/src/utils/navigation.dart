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

  /// Busca: sempre vai para o Catálogo e rola até a área dos produtos.
  void searchCatalog(String value) => go(catalogPath(query: value, toProducts: true));
}

/// Parâmetro que pede para o Catálogo rolar até a área de produtos.
const catalogProductsSection = 'produtos';

/// URL do Catálogo (`/catalogo?busca=&categoria=&secao=produtos`).
String catalogPath({String? query, String? category, bool toProducts = false}) {
  final q = query?.trim() ?? '';
  final params = {
    if (q.isNotEmpty) 'busca': q,
    if (category != null && category.isNotEmpty) 'categoria': category,
    if (toProducts) 'secao': catalogProductsSection,
  };
  return Uri(path: '/catalogo', queryParameters: params.isEmpty ? null : params).toString();
}
