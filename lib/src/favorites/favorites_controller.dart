import 'package:flutter/foundation.dart';

import '../catalog/product.dart';
import '../database/firestore_user_data_repository.dart';

class FavoritesController extends ChangeNotifier {
  FavoritesController(this._repository);

  final FirestoreUserDataRepository _repository;
  final Map<int, Product> _items = {};
  String? _userId;
  int _loadToken = 0;

  List<Product> get items => _items.values.toList();

  bool contains(Product product) => _items.containsKey(product.id);

  Future<void> bindUser(String? userId) async {
    if (_userId == userId) return;

    _userId = userId;
    _loadToken++;
    _items.clear();
    notifyListeners();

    if (userId == null) return;

    final token = _loadToken;
    final savedItems = await _repository.fetchFavorites(userId).catchError(
          (_) => <Product>[],
        );
    if (_userId != userId || token != _loadToken) return;

    for (final product in savedItems) {
      _items[product.id] = product;
    }
    notifyListeners();
  }

  void toggle(Product product) {
    final userId = _userId;
    if (contains(product)) {
      _items.remove(product.id);
      if (userId != null) {
        _repository.removeFavorite(userId, product.id).catchError((_) {});
      }
    } else {
      _items[product.id] = product;
      if (userId != null) {
        _repository.saveFavorite(userId, product).catchError((_) {});
      }
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    final userId = _userId;
    if (userId != null) {
      _repository.clearFavorites(userId).catchError((_) {});
    }
    notifyListeners();
  }
}
