import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../models/app_user.dart';

class NiceAuthException implements Exception {
  const NiceAuthException(this.message);
  final String message;
}

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;
  GoTrueClient get _auth => _client.auth;

  Stream<AuthState> get authChanges => _auth.onAuthStateChange;
  Session? get currentSession => _auth.currentSession;

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
    } on AuthException catch (e) {
      throw NiceAuthException(_message(e));
    }
  }

  /// Retorna true se a sessão já foi criada; false se o projeto exige
  /// confirmação de e-mail antes do primeiro login.
  Future<bool> signUp({required String name, required String email, required String password}) async {
    try {
      final response = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name.trim()},
        emailRedirectTo: AppConfig.authRedirect,
      );
      return response.session != null;
    } on AuthException catch (e) {
      throw NiceAuthException(_message(e));
    }
  }

  /// Google (Android e Web) via OAuth do Supabase.
  Future<void> signInWithGoogle() async {
    try {
      await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: AppConfig.authRedirect,
      );
    } on AuthException catch (e) {
      throw NiceAuthException(_message(e));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.resetPasswordForEmail(email.trim(), redirectTo: AppConfig.authRedirect);
    } on AuthException catch (e) {
      throw NiceAuthException(_message(e));
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Lê o perfil (nome/role) em `profiles`; cai para os metadados se falhar.
  Future<AppUser> fetchProfile(User user) async {
    final metaName = (user.userMetadata?['name'] ?? user.userMetadata?['full_name'])?.toString();
    try {
      final row = await _client.from('profiles').select().eq('id', user.id).maybeSingle();
      final name = (row?['name'] as String?)?.trim();
      return AppUser(
        id: user.id,
        email: user.email ?? (row?['email'] as String?) ?? '',
        name: (name != null && name.isNotEmpty) ? name : (metaName ?? 'Cliente NICE'),
        role: row?['role'] == 'admin' ? UserRole.admin : UserRole.customer,
      );
    } catch (_) {
      return AppUser(id: user.id, email: user.email ?? '', name: metaName ?? 'Cliente NICE');
    }
  }

  String _message(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return 'E-mail ou senha inválidos.';
      case 'email_not_confirmed':
        return 'Confirme seu e-mail antes de entrar.';
      case 'user_already_exists':
      case 'email_exists':
        return 'Este e-mail já está cadastrado.';
      case 'weak_password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return 'Muitas tentativas. Aguarde um pouco e tente de novo.';
      case 'validation_failed':
        return 'Verifique os dados informados.';
      default:
        final msg = e.message.toLowerCase();
        if (msg.contains('network') || msg.contains('socket') || msg.contains('failed host')) {
          return 'Verifique sua conexão e tente novamente.';
        }
        return 'Não foi possível concluir a autenticação.';
    }
  }
}
