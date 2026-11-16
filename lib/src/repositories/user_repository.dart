import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';

/// Gestão de usuários pelo administrador (tabela `profiles`).
class UserRepository {
  UserRepository(this._client);

  final SupabaseClient _client;

  /// RLS: o admin lê todos os perfis.
  Future<List<AppUser>> fetchAll() async {
    final rows = await _client.from('profiles').select().order('created_at', ascending: false);
    return rows.map<AppUser>((row) => AppUser.fromProfile(row)).toList();
  }

  Future<AppUser?> fetchById(String id) async {
    final row = await _client.from('profiles').select().eq('id', id).maybeSingle();
    return row == null ? null : AppUser.fromProfile(row);
  }

  /// Função `set_user_role` (security definer) valida se quem chama é admin.
  Future<void> setRole(String userId, UserRole role) async {
    await _client.rpc('set_user_role', params: {'target': userId, 'new_role': role.name});
  }
}
