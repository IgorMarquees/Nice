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
    required OrderTotals totals,
    required ShippingAddress address,
    required PaymentMethod paymentMethod,
  }) async {
    await _table.insert({
      'user_id': userId,
      'items': [for (final item in items) item.toOrderMap()],
      'subtotal': totals.subtotal,
      'discount': totals.discount,
      'shipping': totals.shipping,
      'total': totals.total,
      'address': address.toMap(),
      'payment_method': paymentMethod.code,
      'status': 'created',
    });
  }

  /// Pedidos de um usuário (o próprio cliente ou, via RLS, o admin).
  Future<List<Order>> fetchByUser(String userId) async {
    final rows = await _table.select().eq('user_id', userId).order('created_at', ascending: false);
    return rows.map<Order>((row) => Order.fromMap(row)).toList();
  }
}
