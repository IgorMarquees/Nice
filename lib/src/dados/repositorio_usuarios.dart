import 'package:supabase_flutter/supabase_flutter.dart';

import 'usuario.dart';

class RepositorioUsuarios {
  RepositorioUsuarios(this._conexao);

  final SupabaseClient _conexao;

  Future<List<Usuario>> buscarTodos() async {
    final registros = await _conexao.from('profiles').select().order('created_at', ascending: false);
    return registros.map<Usuario>((registro) => Usuario.doPerfil(registro)).toList();
  }

  Future<Usuario?> buscarPorId(String id) async {
    final registro = await _conexao.from('profiles').select().eq('id', id).maybeSingle();
    return registro == null ? null : Usuario.doPerfil(registro);
  }

  /// Chama a função do banco que confere se quem pede é admin.
  Future<void> definirPapel(String idUsuario, PapelUsuario papel) async {
    await _conexao.rpc('set_user_role', params: {'target': idUsuario, 'new_role': papel.codigo});
  }
}
