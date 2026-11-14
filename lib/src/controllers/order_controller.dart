import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../repositories/order_repository.dart';

class OrderController extends ChangeNotifier {
  OrderController(this._repository);

  final OrderRepository _repository;

  List<Order> _orders = [];
  bool _loading = false;
  bool _submitting = false;
  String? _error;

  List<Order> get orders => _orders;
  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;

  Future<void> loadMine(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _orders = await _repository.fetchMine(userId);
    } catch (_) {
      _error = 'Não foi possível carregar seus pedidos.';
    }
    _loading = false;
    notifyListeners();
  }

  /// Registra o pedido no Supabase. Retorna true em caso de sucesso.
  Future<bool> placeOrder({
    required String userId,
    required List<CartItem> items,
    required double total,
    required ShippingAddress address,
    required PaymentMethod paymentMethod,
  }) async {
    _submitting = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.create(
        userId: userId,
        items: items,
        total: total,
        address: address,
        paymentMethod: paymentMethod,
      );
      return true;
    } catch (_) {
      _error = 'Não foi possível finalizar a compra.';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  void reset() {
    _orders = [];
    notifyListeners();
  }
}
