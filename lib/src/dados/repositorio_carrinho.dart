import 'package:supabase_flutter/supabase_flutter.dart';

import 'item_carrinho.dart';

class RepositorioCarrinho {
  RepositorioCarrinho(this._conexao);

  final SupabaseClient _conexao;

  SupabaseQueryBuilder get _tabela => _conexao.from('cart_items');

  Future<List<ItemCarrinho>> buscar(String idUsuario) async {
    final registros = await _tabela.select().eq('user_id', idUsuario).order('created_at');
    return registros.map<ItemCarrinho>((registro) => ItemCarrinho.doMapa(registro)).toList();
  }

  /// Grava o item ou atualiza a quantidade se ele já existir.
  Future<void> salvarItem(String idUsuario, ItemCarrinho item) async {
    await _tabela.upsert(item.paraLinha(idUsuario), onConflict: 'user_id,product_id,size');
  }

  Future<void> remover(String idUsuario, ItemCarrinho item) async {
    await _tabela
        .delete()
        .eq('user_id', idUsuario)
        .eq('product_id', item.idProduto)
        .eq('size', item.tamanho);
  }

  Future<void> limpar(String idUsuario) async {
    await _tabela.delete().eq('user_id', idUsuario);
  }
}
