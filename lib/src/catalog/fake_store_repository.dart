import 'dart:convert';

import 'package:http/http.dart' as http;

import 'product.dart';

class FakeStoreRepository {
  static const _baseUrl = 'https://fakestoreapi.com/products';

  Future<List<Product>> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl)).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw Exception('FakeStoreAPI respondeu com ${response.statusCode}');
      }

      final rawProducts = (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
      final clothing = rawProducts.where((item) {
        final category = item['category'] as String;
        return category == "men's clothing" || category == "women's clothing";
      }).toList();

      return [
        for (var index = 0; index < clothing.length; index++)
          Product.fromFakeStore(clothing[index], index),
      ];
    } catch (_) {
      return fallbackProducts;
    }
  }

  List<Product> get fallbackProducts => const [
        Product(
          id: 101,
          title: 'Kuro Essential Tee',
          description: 'Minimalismo que nunca sai de cena',
          price: 99.99,
          imageUrl: 'https://fakestoreapi.com/img/71-3HjGNDUL._AC_SY879._SX._UX._SY._UY_.jpg',
          category: 'Camisetas',
        ),
        Product(
          id: 102,
          title: 'Akira Vision Tee',
          description: 'Arte urbana com influencia japonesa',
          price: 99.99,
          imageUrl: 'https://fakestoreapi.com/img/71li-ujtlUL._AC_UX679_.jpg',
          category: 'Camisetas',
        ),
        Product(
          id: 103,
          title: 'Neon Drift Hoodie',
          description: 'Vibracao noturna com estetica cyberpunk',
          price: 399.99,
          imageUrl: 'https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_.jpg',
          category: 'Moletons',
        ),
        Product(
          id: 104,
          title: 'Yoru Pulse Hoodie',
          description: 'Batida noturna que define seu estilo',
          price: 299.99,
          imageUrl: 'https://fakestoreapi.com/img/71YXzeOuslL._AC_UY879_.jpg',
          category: 'Moletons',
        ),
      ];
}
