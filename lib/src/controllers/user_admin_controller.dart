import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/order.dart';
import '../repositories/address_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/user_repository.dart';

/// Dados completos de um cliente para o painel admin.
class UserDetails {
  const UserDetails({required this.user, required this.addresses, required this.orders});

  final AppUser user;
  final List<SavedAddress> addresses;
  final List<Order> orders;

  UserDetails copyWith({AppUser? user}) =>
      UserDetails(user: user ?? this.user, addresses: addresses, orders: orders);
}

class UserAdminController extends ChangeNotifier {
  UserAdminController(this._users, this._addresses, this._orders);

  final UserRepository _users;
  final AddressRepository _addresses;
  final OrderRepository _orders;

  List<AppUser> _items = [];
  bool _loading = false;
  String? _error;
  String _query = '';

  bool get loading => _loading;
  String? get error => _error;

  List<AppUser> get items {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items
        .where((u) => u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q))
        .toList();
  }

  void search(String value) {
    _query = value;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _users.fetchAll();
    } catch (_) {
      _error = 'Não foi possível carregar os usuários.';
    }
    _loading = false;
    notifyListeners();
  }

  /// Perfil + endereços + pedidos (o RLS libera tudo para o admin).
  Future<UserDetails?> details(String userId) async {
    try {
      final results = await Future.wait([
        _users.fetchById(userId),
        _addresses.fetch(userId),
        _orders.fetchByUser(userId),
      ]);
      final user = results[0] as AppUser?;
      if (user == null) return null;
      return UserDetails(
        user: user,
        addresses: results[1] as List<SavedAddress>,
        orders: results[2] as List<Order>,
      );
    } catch (_) {
      return null;
    }
  }

  /// Promove/rebaixa. Retorna null em caso de sucesso ou a mensagem de erro.
  Future<String?> setRole(AppUser user, UserRole role) async {
    try {
      await _users.setRole(user.id, role);
      final index = _items.indexWhere((u) => u.id == user.id);
      if (index != -1) _items[index] = _items[index].copyWith(role: role);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().contains('self')
          ? 'Você não pode remover o seu próprio acesso de administrador.'
          : 'Não foi possível alterar o perfil do usuário.';
    }
  }
}
