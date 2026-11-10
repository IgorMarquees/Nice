import 'package:flutter/foundation.dart';

import '../database/firestore_user_data_repository.dart';
import 'app_user.dart';
import 'auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._repository, this._userDataRepository);

  final AuthRepository _repository;
  final FirestoreUserDataRepository _userDataRepository;

  AppUser? _user;
  bool _loading = false;
  String? _error;

  AppUser? get user => _user;
  bool get isSignedIn => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  Future<bool> signIn(String email, String password) async {
    return _run(() => _repository.signIn(email: email, password: password));
  }

  Future<bool> signUp(String name, String email, String password) async {
    return _run(() => _repository.signUp(name: name, email: email, password: password));
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _user = null;
    notifyListeners();
  }

  Future<bool> _run(Future<AppUser> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await action();
      await _userDataRepository.saveUserProfile(_user!).catchError((_) {});
      return true;
    } on AuthException catch (exception) {
      _error = exception.message;
      return false;
    } catch (_) {
      _error = 'Nao foi possivel concluir a autenticacao.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
