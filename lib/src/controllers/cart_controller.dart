import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import '../repositories/cart_repository.dart';

class CartController extends ChangeNotifier {
  CartController(this._repository);

  final CartRepository _repository;
  final Map<String, CartItem> _items = {};
  String? _userId;
  int _loadToken = 0;

  List<CartItem> get items => _items.values.toList();
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.values.fold(0, (total, item) => total + item.quantity);
  double get total => _items.values.fold(0, (sum, item) => sum + item.subtotal);

  /// Chamado pelo ProxyProvider quando o usuário muda (login/logout).
  /// Notificações são adiadas para não disparar durante o build.
  void bindUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    final token = ++_loadToken;
    _items.clear();
    Future.microtask(() async {
      notifyListeners();
      if (userId == null) return;
      List<CartItem> saved;
      try {
        saved = await _repository.fetch(userId);
      } catch (_) {
        saved = [];
      }
      if (token != _loadToken) return;
      for (final item in saved) {
        _items[item.key] = item;
      }
      notifyListeners();
    });
  }

  void add(Product product, {required String size}) {
    final fresh = CartItem.fromProduct(product, size: size);
    final current = _items[fresh.key];
    final item = current == null ? fresh : current.copyWith(quantity: current.quantity + 1);
    _items[item.key] = item;
    _persist(item);
    notifyListeners();
  }

  void increase(CartItem item) {
    final updated = item.copyWith(quantity: item.quantity + 1);
    _items[updated.key] = updated;
    _persist(updated);
    notifyListeners();
  }

  void decrease(CartItem item) {
    if (item.quantity <= 1) return remove(item);
    final updated = item.copyWith(quantity: item.quantity - 1);
    _items[updated.key] = updated;
    _persist(updated);
    notifyListeners();
  }

  void remove(CartItem item) {
    _items.remove(item.key);
    final userId = _userId;
    if (userId != null) _repository.remove(userId, item).catchError((_) {});
    notifyListeners();
  }

  void clear() {
    _items.clear();
    final userId = _userId;
    if (userId != null) _repository.clear(userId).catchError((_) {});
    notifyListeners();
  }

  void _persist(CartItem item) {
    final userId = _userId;
    if (userId != null) _repository.upsert(userId, item).catchError((_) {});
  }
}
