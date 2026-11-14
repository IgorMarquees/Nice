import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart_item.dart';

class CartRepository {
  CartRepository(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _table => _client.from('cart_items');

  Future<List<CartItem>> fetch(String userId) async {
    final rows = await _table.select().eq('user_id', userId).order('created_at');
    return rows.map<CartItem>((row) => CartItem.fromMap(row)).toList();
  }

  Future<void> upsert(String userId, CartItem item) async {
    await _table.upsert(item.toRow(userId), onConflict: 'user_id,product_id,size');
  }

  Future<void> remove(String userId, CartItem item) async {
    await _table
        .delete()
        .eq('user_id', userId)
        .eq('product_id', item.productId)
        .eq('size', item.size);
  }

  Future<void> clear(String userId) async {
    await _table.delete().eq('user_id', userId);
  }
}
