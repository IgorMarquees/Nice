import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

/// Fonte de produtos de reserva: evita Home/Novidades vazias quando o
/// Supabase está offline ou ainda sem produtos marcados.
class FakeStoreRepository {
  static const _baseUrl = 'https://fakestoreapi.com/products';

  Future<List<Product>> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl)).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw Exception('FakeStoreAPI respondeu com ${response.statusCode}');
      }
      final raw = (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
      final clothing = raw.where((item) {
        final category = item['category'] as String;
        return category == "men's clothing" || category == "women's clothing";
      }).toList();
      if (clothing.isEmpty) return fallbackProducts;
      return [
        for (var i = 0; i < clothing.length; i++) Product.fromFakeStore(clothing[i], i),
      ];
    } catch (_) {
      return fallbackProducts;
    }
  }

  /// Último recurso (sem internet): mantém a vitrine preenchida.
  List<Product> get fallbackProducts => const [
        Product(
          id: 'fake-101',
          title: 'Kuro Essential Tee',
          description: 'Minimalismo que nunca sai de cena',
          price: 99.99,
          category: 'Camisetas',
          images: ['https://fakestoreapi.com/img/71-3HjGNDUL._AC_SY879._SX._UX._SY._UY_.jpg'],
          sizes: ['P', 'M', 'G', 'GG'],
          stock: 20,
          isFeatured: true,
          isNew: true,
        ),
        Product(
          id: 'fake-102',
          title: 'Akira Vision Tee',
          description: 'Arte urbana com influência japonesa',
          price: 99.99,
          category: 'Camisetas',
          images: ['https://fakestoreapi.com/img/71li-ujtlUL._AC_UX679_.jpg'],
          sizes: ['P', 'M', 'G', 'GG'],
          stock: 20,
          isFeatured: true,
          isNew: true,
        ),
        Product(
          id: 'fake-103',
          title: 'Neon Drift Hoodie',
          description: 'Vibração noturna com estética cyberpunk',
          price: 399.99,
          category: 'Moletons',
          images: ['https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_.jpg'],
          sizes: ['P', 'M', 'G', 'GG'],
          stock: 20,
          isFeatured: true,
          isNew: true,
        ),
        Product(
          id: 'fake-104',
          title: 'Yoru Pulse Hoodie',
          description: 'Batida noturna que define seu estilo',
          price: 299.99,
          category: 'Moletons',
          images: ['https://fakestoreapi.com/img/71YXzeOuslL._AC_UY879_.jpg'],
          sizes: ['P', 'M', 'G', 'GG'],
          stock: 20,
          isFeatured: true,
          isNew: true,
        ),
      ];
}
