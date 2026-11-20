import 'package:supabase_flutter/supabase_flutter.dart';

import 'produto.dart';

class RepositorioProdutos {
  RepositorioProdutos(this._conexao);

  final SupabaseClient _conexao;

  SupabaseQueryBuilder get _tabela => _conexao.from('products');

  /// Busca todos os produtos sem a coluna de estoque.
  Future<List<Produto>> buscarTodos() async {
    final registros = await _tabela.select(Produto.colunasPublicas).order('created_at', ascending: false);
    return registros.map<Produto>((registro) => Produto.doMapa(registro)).toList();
  }

  Future<Produto?> buscarPorId(String id) async {
    final registro = await _tabela.select(Produto.colunasPublicas).eq('id', id).maybeSingle();
    return registro == null ? null : Produto.doMapa(registro);
  }

  /// Lê o estoque por uma função do banco que só o admin pode usar.
  Future<Map<String, int>> buscarEstoque() async {
    final registros = await _conexao.rpc('admin_product_stock') as List;
    return {
      for (final registro in registros.cast<Map>()) registro['id'].toString(): (registro['stock'] as num).toInt(),
    };
  }

  Future<List<Produto>> buscarTodosAdmin() async {
    final produtos = await buscarTodos();
    final estoque = await buscarEstoque();
    return [for (final p in produtos) p.copiarCom(estoque: estoque[p.id] ?? 0)];
  }

  /// Cria o produto quando ele ainda não tem id ou atualiza quando já tem.
  Future<void> salvar(Produto produto) async {
    if (produto.id.isEmpty) {
      await _tabela.insert(produto.paraMapa());
      return;
    }
    await _tabela
        .update({...produto.paraMapa(), 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', produto.id);
  }

  Future<void> definirMarcacoes(String id, {bool? emDestaque, bool? novidade}) async {
    await _tabela.update({
      'is_featured': ?emDestaque,
      'is_new': ?novidade,
    }).eq('id', id);
  }

  /// Aplica o mesmo desconto em vários produtos de uma vez.
  /// Porcentagem zero tira o desconto.
  Future<void> definirDesconto(List<String> ids, {required int percentual, DateTime? comecaEm, DateTime? terminaEm}) async {
    if (ids.isEmpty) return;
    await _tabela.update({
      'discount_percent': percentual,
      'discount_starts_at': percentual == 0 ? null : comecaEm?.toUtc().toIso8601String(),
      'discount_ends_at': percentual == 0 ? null : terminaEm?.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).inFilter('id', ids);
  }

  Future<void> excluir(String id) async {
    await _tabela.delete().eq('id', id);
  }
}
