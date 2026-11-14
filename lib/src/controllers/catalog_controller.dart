import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../repositories/fake_store_repository.dart';
import '../repositories/product_repository.dart';

enum SortOption {
  newest('Mais recentes'),
  priceAsc('Menor preço'),
  priceDesc('Maior preço'),
  name('Nome (A-Z)');

  const SortOption(this.label);
  final String label;
}

class CatalogController extends ChangeNotifier {
  CatalogController(this._products, this._fakeStore);

  static const allCategories = 'Ver tudo';
  static const categories = [allCategories, 'Camisetas', 'Moletons', 'Calças', 'Acessórios'];
  static const sizes = ['P', 'M', 'G', 'GG'];

  final ProductRepository _products;
  final FakeStoreRepository _fakeStore;

  List<Product> _remote = [];
  List<Product> _fallback = [];
  bool _loading = false;
  bool _loaded = false;

  String _query = '';
  String _category = allCategories;
  String? _size;
  double? _maxPrice; // null = sem limite
  SortOption _sort = SortOption.newest;

  bool get loading => _loading;
  bool get loaded => _loaded;
  String get query => _query;
  String get selectedCategory => _category;
  String? get selectedSize => _size;
  SortOption get sort => _sort;

  /// Produtos reais do Supabase; se não houver, usa a FakeStoreAPI.
  List<Product> get _base => _remote.isNotEmpty ? _remote : _fallback;

  List<Product> get featured {
    final flagged = _remote.where((p) => p.isFeatured).toList();
    return flagged.isNotEmpty ? flagged : _fallback.where((p) => p.isFeatured).toList();
  }

  List<Product> get newArrivals {
    final flagged = _remote.where((p) => p.isNew).toList();
    return flagged.isNotEmpty ? flagged : _fallback.where((p) => p.isNew).toList();
  }

  double get highestPrice {
    if (_base.isEmpty) return 500;
    final max = _base.map((p) => p.price).reduce((a, b) => a > b ? a : b);
    return (max / 50).ceil() * 50.0;
  }

  double get maxPrice => _maxPrice ?? highestPrice;

  List<Product> get filtered {
    final q = _query.trim().toLowerCase();
    final list = _base.where((p) {
      final matchesCategory = _category == allCategories || p.category == _category;
      final matchesQuery = q.isEmpty ||
          p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
      final matchesSize = _size == null || p.sizes.contains(_size);
      final matchesPrice = p.price <= maxPrice;
      return matchesCategory && matchesQuery && matchesSize && matchesPrice;
    }).toList();

    switch (_sort) {
      case SortOption.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
      case SortOption.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
      case SortOption.name:
        list.sort((a, b) => a.title.compareTo(b.title));
      case SortOption.newest:
        break; // já vem ordenado por created_at desc
    }
    return list;
  }

  Future<void> load({bool force = false}) async {
    if (_loading || (_loaded && !force)) return;
    _loading = true;
    notifyListeners();

    try {
      _remote = await _products.fetchAll();
    } catch (_) {
      _remote = [];
    }
    final needsFallback = _remote.isEmpty ||
        !_remote.any((p) => p.isFeatured) ||
        !_remote.any((p) => p.isNew);
    if (needsFallback && _fallback.isEmpty) {
      _fallback = await _fakeStore.fetchProducts();
    }

    _loading = false;
    _loaded = true;
    notifyListeners();
  }

  Future<Product?> findById(String id) async {
    for (final p in [..._remote, ..._fallback]) {
      if (p.id == id) return p;
    }
    if (id.startsWith('fake-')) return null;
    try {
      return await _products.fetchById(id);
    } catch (_) {
      return null;
    }
  }

  // ---- Filtros ----
  void applyInitial({String? category, String? query}) {
    _category = categories.contains(category) ? category! : allCategories;
    _query = query ?? '';
    _size = null;
    _maxPrice = null;
    _sort = SortOption.newest;
    notifyListeners();
  }

  void setCategory(String category) {
    _category = category;
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setSize(String? size) {
    _size = size;
    notifyListeners();
  }

  void setMaxPrice(double value) {
    _maxPrice = value >= highestPrice ? null : value;
    notifyListeners();
  }

  void setSort(SortOption option) {
    _sort = option;
    notifyListeners();
  }

  void clearFilters() => applyInitial();
}
