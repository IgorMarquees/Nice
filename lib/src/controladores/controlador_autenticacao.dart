// Controlador de login e cadastro.
// Sabe quem está logado e se a pessoa é administradora.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session;

import '../dados/usuario.dart';
import '../dados/repositorio_autenticacao.dart';

/// Situação do login enquanto o app abre e depois dele.
enum SituacaoLogin { carregando, deslogado, logado }

/// Escuta o Supabase e avisa o app inteiro quando alguém entra ou sai.
class ControladorAutenticacao extends ChangeNotifier {
  /// Começa ouvindo as mudanças de login e já confere se havia uma sessão salva.
  ControladorAutenticacao(this._repositorio) {
    _inscricao = _repositorio.mudancasLogin.listen((estado) => _sincronizar(estado.session));
    _sincronizar(_repositorio.sessaoAtual);
  }

  final RepositorioAutenticacao _repositorio;
  StreamSubscription? _inscricao;

  Usuario? _usuario;
  SituacaoLogin _situacao = SituacaoLogin.carregando;
  bool _ocupado = false;
  String? _erro;
  String? _aviso;
  /// Número que evita que uma resposta antiga do banco sobrescreva uma mais nova.
  int _fichaSincronia = 0;

  Usuario? get usuario => _usuario;
  SituacaoLogin get situacao => _situacao;
  /// Verdadeiro quando existe um usuário logado e com perfil carregado.
  bool get estaLogado => _situacao == SituacaoLogin.logado && _usuario != null;
  bool get ehAdmin => _usuario?.ehAdmin ?? false;
  /// Verdadeiro enquanto uma ação de login ou cadastro está em andamento.
  bool get carregando => _ocupado;
  String? get erro => _erro;
  String? get aviso => _aviso;

  /// Atualiza o usuário sempre que a sessão do Supabase muda.
  Future<void> _sincronizar(Session? sessao) async {
    if (sessao == null) {
      _fichaSincronia++;
      _usuario = null;
      _situacao = SituacaoLogin.deslogado;
      notifyListeners();
      return;
    }
    if (_situacao == SituacaoLogin.logado && _usuario?.id == sessao.user.id) return;

    final token = ++_fichaSincronia;
    final perfil = await _repositorio.buscarPerfil(sessao.user);
    if (token != _fichaSincronia) return;
    _usuario = perfil;
    _situacao = SituacaoLogin.logado;
    notifyListeners();
  }

  /// Login com email e senha.
  Future<bool> entrar(String email, String senha) =>
      _executar(() => _repositorio.entrar(email: email, senha: senha));

  /// Cadastro de uma conta nova.
  Future<bool> cadastrar(String nome, String email, String senha) {
    return _executar(() async {
      final temSessao = await _repositorio.cadastrar(nome: nome, email: email, senha: senha);
      if (!temSessao) {
        _aviso = 'Enviamos um link de confirmação para o seu e-mail. Confirme para entrar.';
      }
    });
  }

  /// Login com a conta Google.
  Future<bool> entrarComGoogle() => _executar(_repositorio.entrarComGoogle);

  /// Envia o email para a pessoa criar uma senha nova.
  Future<bool> enviarRecuperacaoSenha(String email) {
    return _executar(() async {
      await _repositorio.enviarRecuperacaoSenha(email);
      _aviso = 'Se o e-mail estiver cadastrado, você receberá o link para redefinir a senha.';
    });
  }

  /// Encerra a sessão.
  Future<void> sair() => _repositorio.sair();

  /// Usado só nos testes para simular alguém logado.
  @visibleForTesting
  void simularLogin(Usuario usuario) {
    _fichaSincronia++;
    _usuario = usuario;
    _situacao = SituacaoLogin.logado;
    notifyListeners();
  }

  /// Apaga as mensagens de erro e de aviso da tela.
  void limparMensagens() {
    if (_erro == null && _aviso == null) return;
    _erro = null;
    _aviso = null;
    notifyListeners();
  }

  /// Executa uma ação de login e transforma qualquer erro em mensagem para a tela.
  Future<bool> _executar(Future<void> Function() acao) async {
    _ocupado = true;
    _erro = null;
    _aviso = null;
    notifyListeners();
    try {
      await acao();
      return true;
    } on ErroAutenticacao catch (e) {
      _erro = e.mensagem;
      return false;
    } catch (_) {
      _erro = 'Não foi possível concluir a autenticação.';
      return false;
    } finally {
      _ocupado = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _inscricao?.cancel();
    super.dispose();
  }
}
