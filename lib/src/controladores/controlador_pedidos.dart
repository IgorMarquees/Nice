// Controlador dos pedidos.
// Finaliza compras e carrega o histórico do cliente.

import 'package:flutter/foundation.dart';

import '../dados/item_carrinho.dart';
import '../dados/pedido.dart';
import '../dados/repositorio_pedidos.dart';

/// Pedidos do cliente e o envio de pedidos novos.
class ControladorPedidos extends ChangeNotifier {
  ControladorPedidos(this._repositorio);

  final RepositorioPedidos _repositorio;

  List<Pedido> _pedidos = [];
  bool _carregando = false;
  bool _enviando = false;
  String? _erro;

  List<Pedido> get pedidos => _pedidos;
  bool get carregando => _carregando;
  bool get enviando => _enviando;
  String? get erro => _erro;

  /// Carrega o histórico de pedidos do cliente.
  Future<void> carregarMeus(String idUsuario) async {
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      _pedidos = await _repositorio.buscarPorUsuario(idUsuario);
    } catch (_) {
      _erro = 'Não foi possível carregar seus pedidos.';
    }
    _carregando = false;
    notifyListeners();
  }

  /// Grava o pedido no banco e diz se deu certo.
  Future<bool> fazerPedido({
    required String idUsuario,
    required List<ItemCarrinho> itens,
    required TotaisPedido totais,
    required EnderecoEntrega endereco,
    required FormaPagamento formaPagamento,
  }) async {
    _enviando = true;
    _erro = null;
    notifyListeners();
    try {
      await _repositorio.criar(
        idUsuario: idUsuario,
        itens: itens,
        totais: totais,
        endereco: endereco,
        formaPagamento: formaPagamento,
      );
      return true;
    } catch (_) {
      _erro = 'Não foi possível finalizar a compra.';
      return false;
    } finally {
      _enviando = false;
      notifyListeners();
    }
  }

  /// Limpa a lista de pedidos.
  void reiniciar() {
    _pedidos = [];
    notifyListeners();
  }
}
