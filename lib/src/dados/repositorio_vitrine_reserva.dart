// Vitrine reserva com produtos de exemplo.
// Evita que a loja apareça vazia quando o banco está sem produtos.

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'produto.dart';

/// Busca produtos de exemplo na FakeStoreAPI.
class RepositorioVitrineReserva {
  static const _urlBase = 'https://fakestoreapi.com/products';

  /// Pega as roupas da API e transforma em produtos com a cara da NICE.
  Future<List<Produto>> buscarProdutos() async {
    try {
      final resposta = await http.get(Uri.parse(_urlBase)).timeout(const Duration(seconds: 8));
      if (resposta.statusCode != 200) {
        throw Exception('FakeStoreAPI respondeu com ${resposta.statusCode}');
      }
      final bruto = (jsonDecode(resposta.body) as List).cast<Map<String, dynamic>>();
      final roupas = bruto.where((item) {
        final categoria = item['category'] as String;
        return categoria == "men's clothing" || categoria == "women's clothing";
      }).toList();
      if (roupas.isEmpty) return produtosReserva;
      return [
        for (var i = 0; i < roupas.length; i++) Produto.daVitrineReserva(roupas[i], i),
      ];
    } catch (_) {
      return produtosReserva;
    }
  }

  /// Lista fixa usada quando nem a API responde.
  List<Produto> get produtosReserva => const [
        Produto(
          id: 'fake-101',
          titulo: 'Kuro Essential Tee',
          descricao: 'Minimalismo que nunca sai de cena',
          preco: 99.99,
          categoria: 'Camisetas',
          fotos: ['https://fakestoreapi.com/img/71-3HjGNDUL._AC_SY879._SX._UX._SY._UY_.jpg'],
          tamanhos: ['P', 'M', 'G', 'GG'],
          estoque: 20,
          emDestaque: true,
          novidade: true,
        ),
        Produto(
          id: 'fake-102',
          titulo: 'Akira Vision Tee',
          descricao: 'Arte urbana com influência japonesa',
          preco: 99.99,
          categoria: 'Camisetas',
          fotos: ['https://fakestoreapi.com/img/71li-ujtlUL._AC_UX679_.jpg'],
          tamanhos: ['P', 'M', 'G', 'GG'],
          estoque: 20,
          emDestaque: true,
          novidade: true,
        ),
        Produto(
          id: 'fake-103',
          titulo: 'Neon Drift Hoodie',
          descricao: 'Vibração noturna com estética cyberpunk',
          preco: 399.99,
          categoria: 'Moletons',
          fotos: ['https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_.jpg'],
          tamanhos: ['P', 'M', 'G', 'GG'],
          estoque: 20,
          emDestaque: true,
          novidade: true,
        ),
        Produto(
          id: 'fake-104',
          titulo: 'Yoru Pulse Hoodie',
          descricao: 'Batida noturna que define seu estilo',
          preco: 299.99,
          categoria: 'Moletons',
          fotos: ['https://fakestoreapi.com/img/71YXzeOuslL._AC_UY879_.jpg'],
          tamanhos: ['P', 'M', 'G', 'GG'],
          estoque: 20,
          emDestaque: true,
          novidade: true,
        ),
      ];
}
