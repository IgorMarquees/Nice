// Controlador do carrinho.
// Muda a tela na hora e salva no banco por trás.

import 'package:flutter/foundation.dart';

import '../dados/item_carrinho.dart';
import '../dados/produto.dart';
import '../dados/repositorio_carrinho.dart';

/// Carrinho do usuário logado.
class ControladorCarrinho extends ChangeNotifier {
  ControladorCarrinho(this._repositorio);

  final RepositorioCarrinho _repositorio;
  /// Itens guardados pela chave que junta produto e variação.
  final Map<String, ItemCarrinho> _itens = {};
  String? _idUsuario;
  int _fichaCarga = 0;

  List<ItemCarrinho> get itens => _itens.values.toList();
  bool get vazio => _itens.isEmpty;
  /// Quantidade total de peças somando todos os itens.
  int get qtdItens => _itens.values.fold(0, (total, item) => total + item.quantidade);
  /// Valor total do carrinho.
  double get total => _itens.values.fold(0, (soma, item) => soma + item.subtotal);

  /// Chamado quando o usuário muda.
  /// Limpa o carrinho e carrega o carrinho salvo da nova conta.
  void vincularUsuario(String? idUsuario) {
    if (_idUsuario == idUsuario) return;
    _idUsuario = idUsuario;
    final token = ++_fichaCarga;
    _itens.clear();
    Future.microtask(() async {
      notifyListeners();
      if (idUsuario == null) return;
      List<ItemCarrinho> salvo;
      try {
        salvo = await _repositorio.buscar(idUsuario);
      } catch (_) {
        salvo = [];
      }
      if (token != _fichaCarga) return;
      for (final item in salvo) {
        _itens[item.chave] = item;
      }
      notifyListeners();
    });
  }

  /// Coloca o produto no carrinho ou soma mais uma unidade se ele já estiver lá.
  void adicionar(Produto produto, {required String tamanho}) {
    final novo = ItemCarrinho.doProduto(produto, tamanho: tamanho);
    final atual = _itens[novo.chave];
    final item = atual == null ? novo : atual.copiarCom(quantidade: atual.quantidade + 1);
    _itens[item.chave] = item;
    _salvarNoBanco(item);
    notifyListeners();
  }

  /// Soma uma unidade ao item.
  void aumentar(ItemCarrinho item) {
    final atualizado = item.copiarCom(quantidade: item.quantidade + 1);
    _itens[atualizado.chave] = atualizado;
    _salvarNoBanco(atualizado);
    notifyListeners();
  }

  /// Tira uma unidade e remove o item quando chega a zero.
  void diminuir(ItemCarrinho item) {
    if (item.quantidade <= 1) return remover(item);
    final atualizado = item.copiarCom(quantidade: item.quantidade - 1);
    _itens[atualizado.chave] = atualizado;
    _salvarNoBanco(atualizado);
    notifyListeners();
  }

  /// Remove o item inteiro.
  void remover(ItemCarrinho item) {
    _itens.remove(item.chave);
    final idUsuario = _idUsuario;
    if (idUsuario != null) _repositorio.remover(idUsuario, item).catchError((_) {});
    notifyListeners();
  }

  /// Esvazia o carrinho.
  void limpar() {
    _itens.clear();
    final idUsuario = _idUsuario;
    if (idUsuario != null) _repositorio.limpar(idUsuario).catchError((_) {});
    notifyListeners();
  }

  /// Grava o item no banco sem travar a tela.
  void _salvarNoBanco(ItemCarrinho item) {
    final idUsuario = _idUsuario;
    if (idUsuario != null) _repositorio.salvarItem(idUsuario, item).catchError((_) {});
  }
}
