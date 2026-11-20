// Atalhos de navegação usados pelas telas.

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controladores/controlador_autenticacao.dart';

extension NavegacaoNice on BuildContext {
  /// Confere se tem alguém logado.
  /// Se não tiver leva ao login e volta para esta página depois.
  bool exigirLogin() {
    final autenticacao = Provider.of<ControladorAutenticacao>(this, listen: false);
    if (autenticacao.estaLogado) return true;
    final origem = GoRouterState.of(this).uri.toString();
    go('/login?from=${Uri.encodeComponent(origem)}');
    return false;
  }

  /// Volta para a tela anterior ou abre a página indicada.
  void voltarOu(String alternativa) => canPop() ? pop() : go(alternativa);

  /// Toda busca abre o catálogo já rolado até os produtos.
  void buscarNoCatalogo(String valor) => go(caminhoCatalogo(busca: valor, irParaProdutos: true));
}

/// Valor do endereço que pede para o catálogo rolar até os produtos.
const secaoProdutosCatalogo = 'produtos';

/// Monta o endereço do catálogo com busca categoria e rolagem.
String caminhoCatalogo({String? busca, String? categoria, bool irParaProdutos = false}) {
  final q = busca?.trim() ?? '';
  final parametros = {
    if (q.isNotEmpty) 'busca': q,
    if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
    if (irParaProdutos) 'secao': secaoProdutosCatalogo,
  };
  return Uri(path: '/catalogo', queryParameters: parametros.isEmpty ? null : parametros).toString();
}
