import 'package:supabase_flutter/supabase_flutter.dart';

import 'item_carrinho.dart';
import 'pedido.dart';

class RepositorioPedidos {
  RepositorioPedidos(this._conexao);

  final SupabaseClient _conexao;

  SupabaseQueryBuilder get _tabela => _conexao.from('orders');

  Future<void> criar({
    required String idUsuario,
    required List<ItemCarrinho> itens,
    required TotaisPedido totais,
    required EnderecoEntrega endereco,
    required FormaPagamento formaPagamento,
  }) async {
    await _tabela.insert({
      'user_id': idUsuario,
      'items': [for (final item in itens) item.paraMapaPedido()],
      'subtotal': totais.subtotal,
      'discount': totais.desconto,
      'shipping': totais.frete,
      'total': totais.total,
      'address': endereco.paraMapa(),
      'payment_method': formaPagamento.codigo,
      'status': 'created',
    });
  }

  /// Busca os pedidos de um usuário.
  /// O próprio cliente ou o admin podem ler.
  Future<List<Pedido>> buscarPorUsuario(String idUsuario) async {
    final registros = await _tabela.select().eq('user_id', idUsuario).order('created_at', ascending: false);
    return registros.map<Pedido>((registro) => Pedido.doMapa(registro)).toList();
  }
}
