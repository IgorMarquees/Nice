import 'package:supabase_flutter/supabase_flutter.dart';

import '../nucleo/configuracao.dart';
import 'usuario.dart';

class ErroAutenticacao implements Exception {
  const ErroAutenticacao(this.mensagem);
  final String mensagem;
}

class RepositorioAutenticacao {
  RepositorioAutenticacao(this._conexao);

  final SupabaseClient _conexao;
  GoTrueClient get _autenticacao => _conexao.auth;

  Stream<AuthState> get mudancasLogin => _autenticacao.onAuthStateChange;
  Session? get sessaoAtual => _autenticacao.currentSession;

  Future<void> entrar({required String email, required String senha}) async {
    try {
      await _autenticacao.signInWithPassword(email: email.trim(), password: senha);
    } on AuthException catch (e) {
      throw ErroAutenticacao(_mensagem(e));
    }
  }

  /// Cria uma conta.
  /// Devolve falso quando o projeto exige confirmar o email antes.
  Future<bool> cadastrar({required String nome, required String email, required String senha}) async {
    try {
      final resposta = await _autenticacao.signUp(
        email: email.trim(),
        password: senha,
        data: {'name': nome.trim()},
        emailRedirectTo: Configuracao.redirecionamentoLogin,
      );
      return resposta.session != null;
    } on AuthException catch (e) {
      throw ErroAutenticacao(_mensagem(e));
    }
  }

  Future<void> entrarComGoogle() async {
    try {
      await _autenticacao.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Configuracao.redirecionamentoLogin,
      );
    } on AuthException catch (e) {
      throw ErroAutenticacao(_mensagem(e));
    }
  }

  Future<void> enviarRecuperacaoSenha(String email) async {
    try {
      await _autenticacao.resetPasswordForEmail(email.trim(), redirectTo: Configuracao.redirecionamentoLogin);
    } on AuthException catch (e) {
      throw ErroAutenticacao(_mensagem(e));
    }
  }

  Future<void> sair() => _autenticacao.signOut();

  Future<Usuario> buscarPerfil(User usuario) async {
    final nomeMetadados = (usuario.userMetadata?['name'] ?? usuario.userMetadata?['full_name'])?.toString();
    try {
      final registro = await _conexao.from('profiles').select().eq('id', usuario.id).maybeSingle();
      final nome = (registro?['name'] as String?)?.trim();
      return Usuario(
        id: usuario.id,
        email: usuario.email ?? (registro?['email'] as String?) ?? '',
        nome: (nome != null && nome.isNotEmpty) ? nome : (nomeMetadados ?? 'Cliente NICE'),
        papel: registro?['role'] == 'admin' ? PapelUsuario.admin : PapelUsuario.cliente,
      );
    } catch (_) {
      return Usuario(id: usuario.id, email: usuario.email ?? '', nome: nomeMetadados ?? 'Cliente NICE');
    }
  }

  /// Traduz os erros do Supabase para português.
  String _mensagem(AuthException e) {
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
        final textoErro = e.message.toLowerCase();
        if (textoErro.contains('network') || textoErro.contains('socket') || textoErro.contains('failed host')) {
          return 'Verifique sua conexão e tente novamente.';
        }
        return 'Não foi possível concluir a autenticação.';
    }
  }
}
