import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';

class ProductRepository {
  ProductRepository(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _table => _client.from('products');

  /// Leitura pública: a coluna `stock` não é exposta (só `in_stock`).
  Future<List<Product>> fetchAll() async {
    final rows = await _table.select(Product.publicColumns).order('created_at', ascending: false);
    return rows.map<Product>((row) => Product.fromMap(row)).toList();
  }

  Future<Product?> fetchById(String id) async {
    final row = await _table.select(Product.publicColumns).eq('id', id).maybeSingle();
    return row == null ? null : Product.fromMap(row);
  }

  /// Quantidades em estoque (função `admin_product_stock`, só para admin).
  Future<Map<String, int>> fetchStock() async {
    final rows = await _client.rpc('admin_product_stock') as List;
    return {
      for (final row in rows.cast<Map>()) row['id'].toString(): (row['stock'] as num).toInt(),
    };
  }

  /// Produtos com estoque preenchido (painel admin).
  Future<List<Product>> fetchAllForAdmin() async {
    final products = await fetchAll();
    final stock = await fetchStock();
    return [for (final p in products) p.copyWith(stock: stock[p.id] ?? 0)];
  }

  /// Insere (id vazio) ou atualiza. RLS só permite para administradores.
  Future<void> save(Product product) async {
    if (product.id.isEmpty) {
      await _table.insert(product.toMap());
      return;
    }
    await _table
        .update({...product.toMap(), 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', product.id);
  }

  Future<void> setFlags(String id, {bool? isFeatured, bool? isNew}) async {
    await _table.update({
      'is_featured': ?isFeatured,
      'is_new': ?isNew,
    }).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _table.delete().eq('id', id);
  }
}
