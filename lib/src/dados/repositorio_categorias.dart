import 'package:supabase_flutter/supabase_flutter.dart';

/// Erro de categoria com uma mensagem pronta para mostrar na tela.
class ErroCategoria implements Exception {
  const ErroCategoria(this.mensagem);
  final String mensagem;
}

class RepositorioCategorias {
  RepositorioCategorias(this._conexao);

  final SupabaseClient _conexao;

  SupabaseQueryBuilder get _tabela => _conexao.from('categories');

  Future<List<String>> buscarTodas() async {
    final registros = await _tabela.select('name').order('position');
    return [for (final registro in registros) registro['name'] as String];
  }

  Future<void> criar(String nome) async {
    try {
      await _tabela.insert({'name': nome});
    } on PostgrestException catch (e) {
      // 23505 é o código do banco para nome repetido.
      throw ErroCategoria(e.code == '23505' ? 'Já existe uma categoria com esse nome.' : 'Não foi possível criar a categoria.');
    }
  }

  /// A função do banco move os produtos para Sem categoria e apaga a categoria de uma vez só.
  /// Devolve quantos produtos foram movidos.
  Future<int> excluir(String nome) async {
    final movidos = await _conexao.rpc('delete_category', params: {'target': nome});
    return (movidos as num?)?.toInt() ?? 0;
  }
}
