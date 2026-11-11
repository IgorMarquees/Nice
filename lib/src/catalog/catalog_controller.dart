import 'package:flutter/foundation.dart';

import 'fake_store_repository.dart';
import 'product.dart';

class CatalogController extends ChangeNotifier {
  CatalogController(this._repository);

  final FakeStoreRepository _repository;

  List<Product> _products = [];
  bool _loading = false;
  String _selectedCategory = 'Ver tudo';
  String _query = '';

  List<Product> get products {
    return _products.where((product) {
      final matchesCategory = _selectedCategory == 'Ver tudo' || product.category == _selectedCategory;
      final matchesQuery = _query.isEmpty ||
          product.title.toLowerCase().contains(_query.toLowerCase()) ||
          product.description.toLowerCase().contains(_query.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  bool get loading => _loading;
  String get selectedCategory => _selectedCategory;
  List<String> get categories => const ['Ver tudo', 'Camisetas', 'Moletons', 'Calcas', 'Acessorios'];

  Future<void> load() async {
    if (_products.isNotEmpty) return;
    _loading = true;
    notifyListeners();
    _products = await _repository.fetchProducts();
    _loading = false;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void search(String value) {
    _query = value;
    notifyListeners();
  }
}
