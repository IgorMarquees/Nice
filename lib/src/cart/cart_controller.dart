import 'package:flutter/foundation.dart';

import '../catalog/product.dart';
import '../database/firestore_user_data_repository.dart';
import 'cart_item.dart';

class CartController extends ChangeNotifier {
  CartController(this._repository);

  final FirestoreUserDataRepository _repository;
  final Map<int, CartItem> _items = {};
  String? _userId;
  int _loadToken = 0;

  List<CartItem> get items => _items.values.toList();
  int get itemCount => _items.values.fold(0, (total, item) => total + item.quantity);
  double get total => _items.values.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> bindUser(String? userId) async {
    if (_userId == userId) return;

    _userId = userId;
    _loadToken++;
    _items.clear();
    notifyListeners();

    if (userId == null) return;

    final token = _loadToken;
    final savedItems = await _repository.fetchCart(userId).catchError(
          (_) => <CartItem>[],
        );
    if (_userId != userId || token != _loadToken) return;

    for (final item in savedItems) {
      _items[item.product.id] = item;
    }
    notifyListeners();
  }

  void add(Product product) {
    final current = _items[product.id];
    _items[product.id] = current == null
        ? CartItem(product: product, quantity: 1)
        : current.copyWith(quantity: current.quantity + 1);
    _save(product);
    notifyListeners();
  }

  void decrease(Product product) {
    final current = _items[product.id];
    if (current == null) return;

    if (current.quantity <= 1) {
      _items.remove(product.id);
      _remove(product);
    } else {
      _items[product.id] = current.copyWith(quantity: current.quantity - 1);
      _save(product);
    }
    notifyListeners();
  }

  void remove(Product product) {
    _items.remove(product.id);
    _remove(product);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    final userId = _userId;
    if (userId != null) {
      _repository.clearCart(userId).catchError((_) {});
    }
    notifyListeners();
  }

  void _save(Product product) {
    final userId = _userId;
    final item = _items[product.id];
    if (userId != null && item != null) {
      _repository.saveCartItem(userId, item).catchError((_) {});
    }
  }

  void _remove(Product product) {
    final userId = _userId;
    if (userId != null) {
      _repository.removeCartItem(userId, product.id).catchError((_) {});
    }
  }
}
