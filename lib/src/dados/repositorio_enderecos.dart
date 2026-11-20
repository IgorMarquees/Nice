// Acesso aos endereços salvos e à consulta de CEP.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../nucleo/configuracao.dart';
import 'pedido.dart';

/// Dados que a API de CEP devolve.
class ResultadoCep {
  const ResultadoCep({
    required this.rua,
    required this.bairro,
    required this.cidade,
    required this.estado,
  });

  final String rua;
  final String bairro;
  final String cidade;
  final String estado;
}

/// Endereços na tabela addresses e consulta no ViaCEP.
class RepositorioEnderecos {
  RepositorioEnderecos(this._conexao, {http.Client? clienteHttp}) : _http = clienteHttp ?? http.Client();

  final SupabaseClient _conexao;
  final http.Client _http;

  SupabaseQueryBuilder get _tabela => _conexao.from('addresses');

  /// Busca os endereços do cliente.
  Future<List<EnderecoSalvo>> buscar(String idUsuario) async {
    final registros = await _tabela.select().eq('user_id', idUsuario).order('created_at');
    return registros.map<EnderecoSalvo>((registro) => EnderecoSalvo.doMapa(registro)).toList();
  }

  /// Grava ou atualiza um endereço.
  Future<EnderecoSalvo> salvar(String idUsuario, EnderecoSalvo endereco) async {
    final registro = await _tabela.upsert(endereco.paraLinha(idUsuario)).select().single();
    return EnderecoSalvo.doMapa(registro);
  }

  /// Exclui um endereço.
  Future<void> excluir(String id) async {
    await _tabela.delete().eq('id', id);
  }

  /// Consulta o ViaCEP.
  /// Devolve nada quando o CEP não existe.
  Future<ResultadoCep?> consultarCep(String cep) async {
    final digitos = cep.replaceAll(RegExp(r'\D'), '');
    if (digitos.length != 8) return null;
    final resposta = await _http.get(Uri.parse(Configuracao.urlCep(digitos))).timeout(const Duration(seconds: 8));
    if (resposta.statusCode != 200) return null;
    final dados = jsonDecode(resposta.body) as Map<String, dynamic>;
    if (dados['erro'] != null) return null;
    return ResultadoCep(
      rua: (dados['logradouro'] as String?) ?? '',
      bairro: (dados['bairro'] as String?) ?? '',
      cidade: (dados['localidade'] as String?) ?? '',
      estado: (dados['uf'] as String?) ?? '',
    );
  }
}
