import 'package:flutter/foundation.dart';

import '../dados/item_carrinho.dart';
import '../dados/produto.dart';
import '../dados/repositorio_carrinho.dart';

class ControladorCarrinho extends ChangeNotifier {
  ControladorCarrinho(this._repositorio);

  final RepositorioCarrinho _repositorio;
  /// Itens guardados pela chave que junta produto e variação.
  final Map<String, ItemCarrinho> _itens = {};
  String? _idUsuario;
  int _fichaCarga = 0;

  List<ItemCarrinho> get itens => _itens.values.toList();
  bool get vazio => _itens.isEmpty;
  int get qtdItens => _itens.values.fold(0, (total, item) => total + item.quantidade);
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

  void adicionar(Produto produto, {required String tamanho}) {
    final novo = ItemCarrinho.doProduto(produto, tamanho: tamanho);
    final atual = _itens[novo.chave];
    final item = atual == null ? novo : atual.copiarCom(quantidade: atual.quantidade + 1);
    _itens[item.chave] = item;
    _salvarNoBanco(item);
    notifyListeners();
  }

  void aumentar(ItemCarrinho item) {
    final atualizado = item.copiarCom(quantidade: item.quantidade + 1);
    _itens[atualizado.chave] = atualizado;
    _salvarNoBanco(atualizado);
    notifyListeners();
  }

  void diminuir(ItemCarrinho item) {
    if (item.quantidade <= 1) return remover(item);
    final atualizado = item.copiarCom(quantidade: item.quantidade - 1);
    _itens[atualizado.chave] = atualizado;
    _salvarNoBanco(atualizado);
    notifyListeners();
  }

  void remover(ItemCarrinho item) {
    _itens.remove(item.chave);
    final idUsuario = _idUsuario;
    if (idUsuario != null) _repositorio.remover(idUsuario, item).catchError((_) {});
    notifyListeners();
  }

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
