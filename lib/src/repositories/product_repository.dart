import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';

class ProductRepository {
  ProductRepository(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _table => _client.from('products');

  Future<List<Product>> fetchAll() async {
    final rows = await _table.select().order('created_at', ascending: false);
    return rows.map<Product>((row) => Product.fromMap(row)).toList();
  }

  Future<Product?> fetchById(String id) async {
    final row = await _table.select().eq('id', id).maybeSingle();
    return row == null ? null : Product.fromMap(row);
  }

  /// Insere (id vazio) ou atualiza. RLS só permite para administradores.
  Future<Product> save(Product product) async {
    if (product.id.isEmpty) {
      final row = await _table.insert(product.toMap()).select().single();
      return Product.fromMap(row);
    }
    final row = await _table
        .update({...product.toMap(), 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', product.id)
        .select()
        .single();
    return Product.fromMap(row);
  }

  Future<void> setFlags(String id, {bool? isFeatured, bool? isNew}) async {
    await _table.update({
      if (isFeatured != null) 'is_featured': isFeatured,
      if (isNew != null) 'is_new': isNew,
    }).eq('id', id);
  }

  Future<void> delete(String id) async {
    await _table.delete().eq('id', id);
  }
}
