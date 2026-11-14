import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/config/app_config.dart';
import 'src/controllers/admin_controller.dart';
import 'src/controllers/auth_controller.dart';
import 'src/controllers/cart_controller.dart';
import 'src/controllers/catalog_controller.dart';
import 'src/controllers/order_controller.dart';
import 'src/repositories/auth_repository.dart';
import 'src/repositories/cart_repository.dart';
import 'src/repositories/fake_store_repository.dart';
import 'src/repositories/order_repository.dart';
import 'src/repositories/product_repository.dart';
import 'src/repositories/storage_repository.dart';
import 'src/theme/nice_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // URLs limpas na Web (/produto/123) em vez de /#/produto/123.
  usePathUrlStrategy();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: NiceTheme.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  if (!AppConfig.isSupabaseConfigured) {
    debugPrint('⚠️ Supabase não configurado: use --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...');
  }
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  final client = Supabase.instance.client;

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => AuthRepository(client)),
        Provider(create: (_) => ProductRepository(client)),
        Provider(create: (_) => FakeStoreRepository()),
        Provider(create: (_) => CartRepository(client)),
        Provider(create: (_) => OrderRepository(client)),
        Provider(create: (_) => StorageRepository(client)),
        ChangeNotifierProvider(
          create: (context) => AuthController(context.read<AuthRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => CatalogController(
            context.read<ProductRepository>(),
            context.read<FakeStoreRepository>(),
          )..load(),
        ),
        ChangeNotifierProxyProvider<AuthController, CartController>(
          create: (context) => CartController(context.read<CartRepository>()),
          update: (_, auth, cart) => cart!..bindUser(auth.user?.id),
        ),
        ChangeNotifierProvider(
          create: (context) => OrderController(context.read<OrderRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => AdminController(
            context.read<ProductRepository>(),
            context.read<StorageRepository>(),
          ),
        ),
      ],
      child: const NiceApp(),
    ),
  );
}
