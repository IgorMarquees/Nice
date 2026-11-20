// Configurações fixas do app.

import 'package:flutter/foundation.dart';

/// Endereço do Supabase e regras de frete e Pix.
class Configuracao {
  Configuracao._();

  /// Endereço do projeto no Supabase.
  /// Pode ser trocado ao rodar o app sem mexer no código.
  static const urlSupabase = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://bfgxfovglgadvzxrewqo.supabase.co',
  );
  /// Chave pública do Supabase.
  /// É segura porque as regras do banco protegem os dados.
  static const chaveSupabase = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_ftHYmk7sptm5QeBdb8SENw_XQX0e4YK',
  );

  /// Pasta do Supabase onde ficam as fotos dos produtos.
  static const bucketProdutos = 'product-images';

  /// Endereço de volta para o app depois do login com Google no celular.
  static const redirecionamentoCelular = 'io.supabase.nicestore://login-callback/';

  /// Para onde o Supabase devolve o usuário depois do login.
  static String get redirecionamentoLogin => kIsWeb ? Uri.base.origin : redirecionamentoCelular;

  static bool get supabaseConfigurado =>
      !urlSupabase.contains('SEU-PROJETO') && !chaveSupabase.contains('SUA-ANON');

  /// O botão do Google aparece só no Android e na web.
  static bool get mostrarLoginGoogle =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.android;

  /// Frete grátis a partir deste valor em produtos.
  static const freteGratisAPartirDe = 400.0;

  /// Frete cobrado abaixo do valor mínimo.
  static const freteFixo = 24.90;

  /// Desconto do Pix sobre o valor dos produtos.
  static const descontoPix = 0.05;

  /// Endereço da API de CEP gratuita.
  static String urlCep(String digitos) => 'https://viacep.com.br/ws/$digitos/json/';
}
