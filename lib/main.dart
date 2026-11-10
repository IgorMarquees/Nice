import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'src/app.dart';
import 'src/auth/auth_controller.dart';
import 'src/auth/auth_repository.dart';
import 'src/catalog/catalog_controller.dart';
import 'src/catalog/fake_store_repository.dart';
import 'src/cart/cart_controller.dart';
import 'src/database/firestore_user_data_repository.dart';
import 'src/favorites/favorites_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => FakeStoreRepository()),
        Provider(create: (_) => FirestoreUserDataRepository()),
        ChangeNotifierProvider(
          create: (context) => AuthController(
            FirebaseAuthRepository(),
            context.read<FirestoreUserDataRepository>(),
          ),
        ),
        ChangeNotifierProxyProvider<AuthController, CartController>(
          create: (context) => CartController(
            context.read<FirestoreUserDataRepository>(),
          ),
          update: (_, auth, controller) {
            final cartController = controller!;
            cartController.bindUser(auth.user?.id);
            return cartController;
          },
        ),
        ChangeNotifierProxyProvider<AuthController, FavoritesController>(
          create: (context) => FavoritesController(
            context.read<FirestoreUserDataRepository>(),
          ),
          update: (_, auth, controller) {
            final favoritesController = controller!;
            favoritesController.bindUser(auth.user?.id);
            return favoritesController;
          },
        ),
        ChangeNotifierProxyProvider<FakeStoreRepository, CatalogController>(
          create: (context) =>
              CatalogController(context.read<FakeStoreRepository>()),
          update: (_, repository, controller) =>
              controller ?? CatalogController(repository),
        ),
      ],
      child: const NiceApp(),
    ),
  );
}