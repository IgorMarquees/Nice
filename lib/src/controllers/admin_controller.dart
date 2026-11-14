import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';
import '../repositories/storage_repository.dart';

class AdminController extends ChangeNotifier {
  AdminController(this._products, this._storage);

  final ProductRepository _products;
  final StorageRepository _storage;

  List<Product> _items = [];
  bool _loading = false;
  bool _saving = false;
  String? _error;
  String _query = '';

  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;

  List<Product> get items {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items
        .where((p) => p.title.toLowerCase().contains(q) || p.category.toLowerCase().contains(q))
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
      _items = await _products.fetchAll();
    } catch (_) {
      _error = 'Não foi possível carregar os produtos.';
    }
    _loading = false;
    notifyListeners();
  }

  Future<Product?> findById(String id) async {
    for (final p in _items) {
      if (p.id == id) return p;
    }
    try {
      return await _products.fetchById(id);
    } catch (_) {
      return null;
    }
  }

  /// Sobe as novas imagens para o Storage e grava o produto.
  Future<bool> save(Product product, {List<XFile> newImages = const []}) async {
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      final urls = [...product.images];
      for (final file in newImages) {
        urls.add(await _storage.uploadProductImage(file));
      }
      await _products.save(product.copyWith(images: urls));
      await load();
      return true;
    } catch (_) {
      _error = 'Não foi possível salvar o produto. Verifique se você é administrador.';
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> setFlags(Product product, {bool? isFeatured, bool? isNew}) async {
    final index = _items.indexWhere((p) => p.id == product.id);
    if (index == -1) return false;
    final previous = _items[index];
    _items[index] = previous.copyWith(isFeatured: isFeatured, isNew: isNew);
    notifyListeners();
    try {
      await _products.setFlags(product.id, isFeatured: isFeatured, isNew: isNew);
      return true;
    } catch (_) {
      _items[index] = previous;
      _error = 'Não foi possível atualizar o produto.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(Product product) async {
    try {
      await _products.delete(product.id);
      _items.removeWhere((p) => p.id == product.id);
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Não foi possível excluir o produto.';
      notifyListeners();
      return false;
    }
  }
}
