import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product.dart';
import '../repositories/product_repository.dart';
import '../repositories/storage_repository.dart';

/// Cor em edição no formulário: fotos já salvas + arquivos novos a enviar.
class VariantDraft {
  const VariantDraft({required this.name, this.images = const [], this.newFiles = const []});

  final String name;
  final List<String> images;
  final List<XFile> newFiles;
}

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

  /// Todos os produtos, sem o filtro de busca da lista de produtos.
  List<Product> get all => _items;

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
      _items = await _products.fetchAllForAdmin();
    } catch (_) {
      _error = 'Não foi possível carregar os produtos. Rode o SQL de atualização no Supabase.';
    }
    _loading = false;
    notifyListeners();
  }

  Future<Product?> findById(String id) async {
    if (_items.isEmpty) await load();
    for (final p in _items) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Sobe as fotos novas (gerais e de cada cor) e grava o produto.
  Future<bool> save(
    Product product, {
    List<XFile> newImages = const [],
    List<VariantDraft> variants = const [],
  }) async {
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      final general = [...product.images];
      for (final file in newImages) {
        general.add(await _storage.uploadProductImage(file));
      }
      final colorVariants = <ColorVariant>[];
      for (final draft in variants) {
        final urls = [...draft.images];
        for (final file in draft.newFiles) {
          urls.add(await _storage.uploadProductImage(file));
        }
        colorVariants.add(ColorVariant(name: draft.name, images: urls));
      }
      await _products.save(product.copyWith(images: general, colorVariants: colorVariants));
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

  /// Aplica um desconto com período a vários produtos (ou a um só).
  Future<bool> applyDiscount(List<String> ids, {required int percent, DateTime? startsAt, DateTime? endsAt}) async {
    return _bulk(() => _products.setDiscount(ids, percent: percent, startsAt: startsAt, endsAt: endsAt),
        'Não foi possível aplicar o desconto.');
  }

  /// Cancela o desconto de vários produtos (ou de um só).
  Future<bool> cancelDiscount(List<String> ids) {
    return _bulk(() => _products.setDiscount(ids, percent: 0), 'Não foi possível cancelar o desconto.');
  }

  Future<bool> _bulk(Future<void> Function() action, String errorMessage) async {
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      await load();
      return true;
    } catch (_) {
      _error = errorMessage;
      return false;
    } finally {
      _saving = false;
      notifyListeners();
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
