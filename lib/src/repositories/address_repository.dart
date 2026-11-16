import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../models/order.dart';

/// Resultado da consulta de CEP (campos que a API devolve).
class CepResult {
  const CepResult({
    required this.street,
    required this.neighborhood,
    required this.city,
    required this.state,
  });

  final String street;
  final String neighborhood;
  final String city;
  final String state;
}

class AddressRepository {
  AddressRepository(this._client, {http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final SupabaseClient _client;
  final http.Client _http;

  SupabaseQueryBuilder get _table => _client.from('addresses');

  Future<List<SavedAddress>> fetch(String userId) async {
    final rows = await _table.select().eq('user_id', userId).order('created_at');
    return rows.map<SavedAddress>((row) => SavedAddress.fromMap(row)).toList();
  }

  Future<SavedAddress> save(String userId, SavedAddress address) async {
    final row = await _table.upsert(address.toRow(userId)).select().single();
    return SavedAddress.fromMap(row);
  }

  Future<void> delete(String id) async {
    await _table.delete().eq('id', id);
  }

  /// Consulta o ViaCEP. Retorna null se o CEP não existir.
  Future<CepResult?> lookupCep(String cep) async {
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;
    final response = await _http.get(Uri.parse(AppConfig.cepUrl(digits))).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['erro'] != null) return null;
    return CepResult(
      street: (data['logradouro'] as String?) ?? '',
      neighborhood: (data['bairro'] as String?) ?? '',
      city: (data['localidade'] as String?) ?? '',
      state: (data['uf'] as String?) ?? '',
    );
  }
}
