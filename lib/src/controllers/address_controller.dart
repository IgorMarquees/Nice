import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../repositories/address_repository.dart';

/// Endereços salvos do usuário logado + consulta de CEP.
class AddressController extends ChangeNotifier {
  AddressController(this._repository);

  final AddressRepository _repository;

  List<SavedAddress> _items = [];
  String? _userId;
  bool _loading = false;
  bool _saving = false;
  String? _error;
  int _loadToken = 0;

  List<SavedAddress> get items => _items;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;

  /// Chamado pelo ProxyProvider quando o usuário muda (login/logout).
  void bindUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _items = [];
    final token = ++_loadToken;
    // Adiado para não notificar durante o build.
    Future.microtask(() async {
      if (token != _loadToken) return;
      if (userId == null) {
        notifyListeners();
        return;
      }
      await _load(userId, token);
    });
  }

  Future<void> reload() async {
    final userId = _userId;
    if (userId != null) await _load(userId, ++_loadToken);
  }

  Future<void> _load(String userId, int token) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final items = await _repository.fetch(userId);
      if (token != _loadToken) return;
      _items = items;
    } catch (_) {
      if (token != _loadToken) return;
      _error = 'Não foi possível carregar seus endereços.';
    }
    _loading = false;
    notifyListeners();
  }

  /// Insere ou atualiza. Retorna o endereço gravado (ou null em caso de erro).
  Future<SavedAddress?> save(SavedAddress address) async {
    final userId = _userId;
    if (userId == null) return null;
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _repository.save(userId, address);
      final index = _items.indexWhere((a) => a.id == saved.id);
      _items = index == -1 ? [..._items, saved] : ([..._items]..[index] = saved);
      return saved;
    } catch (_) {
      _error = 'Não foi possível salvar o endereço.';
      return null;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> delete(SavedAddress address) async {
    try {
      await _repository.delete(address.id);
      _items = _items.where((a) => a.id != address.id).toList();
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Não foi possível excluir o endereço.';
      notifyListeners();
      return false;
    }
  }

  Future<CepResult?> lookupCep(String cep) async {
    try {
      return await _repository.lookupCep(cep);
    } catch (_) {
      return null;
    }
  }
}
