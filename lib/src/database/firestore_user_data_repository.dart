import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/app_user.dart';
import '../cart/cart_item.dart';
import '../catalog/product.dart';

class FirestoreUserDataRepository {
  FirestoreUserDataRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> _cart(String userId) =>
      _users.doc(userId).collection('cart');

  CollectionReference<Map<String, dynamic>> _favorites(String userId) =>
      _users.doc(userId).collection('favorites');

  CollectionReference<Map<String, dynamic>> _orders(String userId) =>
      _users.doc(userId).collection('orders');

  Future<void> saveUserProfile(AppUser user) {
    return _users.doc(user.id).set({
      'name': user.name,
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<CartItem>> fetchCart(String userId) async {
    final snapshot = await _cart(userId).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return CartItem(
        product: Product.fromMap(
          Map<String, dynamic>.from(data['product'] as Map),
        ),
        quantity: (data['quantity'] as num).toInt(),
      );
    }).toList();
  }

  Future<void> saveCartItem(String userId, CartItem item) {
    return _cart(userId).doc(item.product.id.toString()).set({
      'product': item.product.toMap(),
      'quantity': item.quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeCartItem(String userId, int productId) {
    return _cart(userId).doc(productId.toString()).delete();
  }

  Future<void> clearCart(String userId) async {
    final snapshot = await _cart(userId).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<List<Product>> fetchFavorites(String userId) async {
    final snapshot = await _favorites(userId).get();
    return snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList();
  }

  Future<void> saveFavorite(String userId, Product product) {
    return _favorites(userId).doc(product.id.toString()).set({
      ...product.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFavorite(String userId, int productId) {
    return _favorites(userId).doc(productId.toString()).delete();
  }

  Future<void> clearFavorites(String userId) async {
    final snapshot = await _favorites(userId).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> createOrder({
    required String userId,
    required List<CartItem> items,
    required double total,
  }) async {
    await _orders(userId).add({
      'items': [
        for (final item in items)
          {
            'product': item.product.toMap(),
            'quantity': item.quantity,
            'subtotal': item.subtotal,
          },
      ],
      'total': total,
      'status': 'created',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
