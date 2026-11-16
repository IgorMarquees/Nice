import 'package:flutter/foundation.dart';

/// Configurações do app. Os valores do Supabase podem ser passados em build:
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
/// (a chave "anon" é pública; NUNCA coloque a "service_role" no app).
class AppConfig {
  AppConfig._();

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://bfgxfovglgadvzxrewqo.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_ftHYmk7sptm5QeBdb8SENw_XQX0e4YK',
  );

  /// Bucket público do Supabase Storage onde ficam as fotos dos produtos.
  static const productsBucket = 'product-images';

  /// Deep link usado no retorno do login Google (Android) e no e-mail de confirmação.
  static const mobileRedirect = 'io.supabase.nicestore://login-callback/';

  /// Para onde o Supabase devolve o usuário depois do OAuth / e-mail.
  static String get authRedirect => kIsWeb ? Uri.base.origin : mobileRedirect;

  static bool get isSupabaseConfigured =>
      !supabaseUrl.contains('SEU-PROJETO') && !supabaseAnonKey.contains('SUA-ANON');

  /// Google aparece no Android e na Web. No iOS o login é só por e-mail/senha.
  static bool get showGoogleLogin =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.android;

  // ---- Regras comerciais ----

  /// Frete grátis a partir deste valor (em produtos).
  static const freeShippingThreshold = 400.0;

  /// Frete fixo abaixo do mínimo (não há cálculo por CEP).
  static const flatShipping = 24.90;

  /// Desconto do Pix sobre o valor dos produtos (já com promoções).
  static const pixDiscount = 0.05;

  /// API pública de CEP (sem chave; suporta CORS na Web).
  static String cepUrl(String digits) => 'https://viacep.com.br/ws/$digits/json/';
}
