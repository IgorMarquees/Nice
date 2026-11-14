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

  // Plataformas que exibem cada provedor social.
  static bool get showGoogleLogin =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.android;
  static bool get showAppleLogin =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}
