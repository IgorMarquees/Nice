import 'package:firebase_auth/firebase_auth.dart';

import 'app_user.dart';

abstract class AuthRepository {
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> signUp({required String name, required String email, required String password});
  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _toAppUser(credential.user, fallbackEmail: email);
    } on FirebaseAuthException catch (exception) {
      throw AuthException(_messageFor(exception));
    }
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final displayName = name.trim().isEmpty ? 'Cliente NICE' : name.trim();
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(displayName);
      await credential.user?.reload();

      return _toAppUser(
        _auth.currentUser ?? credential.user,
        fallbackEmail: email,
        fallbackName: displayName,
      );
    } on FirebaseAuthException catch (exception) {
      throw AuthException(_messageFor(exception));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  AppUser _toAppUser(
    User? user, {
    required String fallbackEmail,
    String? fallbackName,
  }) {
    if (user == null) {
      throw const AuthException('Nao foi possivel concluir a autenticacao.');
    }

    return AppUser(
      id: user.uid,
      email: user.email ?? fallbackEmail.trim(),
      name: user.displayName ?? fallbackName ?? 'Cliente NICE',
    );
  }

  String _messageFor(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'email-already-in-use':
        return 'Este email ja esta cadastrado.';
      case 'invalid-email':
        return 'Email invalido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou senha invalidos.';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'network-request-failed':
        return 'Verifique sua conexao e tente novamente.';
      default:
        return 'Nao foi possivel concluir a autenticacao.';
    }
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}
