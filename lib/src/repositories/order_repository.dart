import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart_item.dart';
import '../models/order.dart';

class OrderRepository {
  OrderRepository(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _table => _client.from('orders');

  Future<void> create({
    required String userId,
    required List<CartItem> items,
    required double total,
    required ShippingAddress address,
    required PaymentMethod paymentMethod,
  }) async {
    await _table.insert({
      'user_id': userId,
      'items': [for (final item in items) item.toOrderMap()],
      'total': total,
      'address': address.toMap(),
      'payment_method': paymentMethod.code,
      'status': 'created',
    });
  }

  Future<List<Order>> fetchMine(String userId) async {
    final rows = await _table.select().eq('user_id', userId).order('created_at', ascending: false);
    return rows.map<Order>((row) => Order.fromMap(row)).toList();
  }
}
