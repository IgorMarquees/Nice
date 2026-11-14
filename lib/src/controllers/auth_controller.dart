import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session;

import '../models/app_user.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { loading, signedOut, signedIn }

class AuthController extends ChangeNotifier {
  AuthController(this._repository) {
    _subscription = _repository.authChanges.listen((state) => _sync(state.session));
    _sync(_repository.currentSession);
  }

  final AuthRepository _repository;
  StreamSubscription? _subscription;

  AppUser? _user;
  AuthStatus _status = AuthStatus.loading;
  bool _busy = false;
  String? _error;
  String? _info;
  int _syncToken = 0;

  AppUser? get user => _user;
  AuthStatus get status => _status;
  bool get isSignedIn => _status == AuthStatus.signedIn && _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get loading => _busy;
  String? get error => _error;
  String? get info => _info;

  Future<void> _sync(Session? session) async {
    if (session == null) {
      _syncToken++;
      _user = null;
      _status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }
    // Renovação de token do mesmo usuário não precisa recarregar o perfil.
    if (_status == AuthStatus.signedIn && _user?.id == session.user.id) return;

    final token = ++_syncToken;
    final profile = await _repository.fetchProfile(session.user);
    if (token != _syncToken) return;
    _user = profile;
    _status = AuthStatus.signedIn;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) =>
      _run(() => _repository.signIn(email: email, password: password));

  Future<bool> signUp(String name, String email, String password) {
    return _run(() async {
      final hasSession = await _repository.signUp(name: name, email: email, password: password);
      if (!hasSession) {
        _info = 'Enviamos um link de confirmação para o seu e-mail. Confirme para entrar.';
      }
    });
  }

  Future<bool> signInWithGoogle() => _run(_repository.signInWithGoogle);
  Future<bool> signInWithApple() => _run(_repository.signInWithApple);

  Future<bool> sendPasswordReset(String email) {
    return _run(() async {
      await _repository.sendPasswordReset(email);
      _info = 'Se o e-mail estiver cadastrado, você receberá o link para redefinir a senha.';
    });
  }

  Future<void> signOut() => _repository.signOut();

  void clearMessages() {
    if (_error == null && _info == null) return;
    _error = null;
    _info = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    _info = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on NiceAuthException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Não foi possível concluir a autenticação.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
