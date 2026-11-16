import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nice_store/src/controllers/address_controller.dart';
import 'package:nice_store/src/controllers/admin_controller.dart';
import 'package:nice_store/src/controllers/auth_controller.dart';
import 'package:nice_store/src/controllers/cart_controller.dart';
import 'package:nice_store/src/controllers/catalog_controller.dart';
import 'package:nice_store/src/controllers/order_controller.dart';
import 'package:nice_store/src/controllers/user_admin_controller.dart';
import 'package:nice_store/src/models/app_user.dart';
import 'package:nice_store/src/models/product.dart';
import 'package:nice_store/src/repositories/address_repository.dart';
import 'package:nice_store/src/repositories/auth_repository.dart';
import 'package:nice_store/src/repositories/cart_repository.dart';
import 'package:nice_store/src/repositories/fake_store_repository.dart';
import 'package:nice_store/src/repositories/order_repository.dart';
import 'package:nice_store/src/repositories/product_repository.dart';
import 'package:nice_store/src/repositories/storage_repository.dart';
import 'package:nice_store/src/repositories/user_repository.dart';
import 'package:nice_store/src/utils/navigation.dart';
import 'package:nice_store/src/screens/about_screen.dart';
import 'package:nice_store/src/screens/admin/admin_dashboard_screen.dart';
import 'package:nice_store/src/screens/admin/admin_discounts_screen.dart';
import 'package:nice_store/src/screens/admin/admin_product_form_screen.dart';
import 'package:nice_store/src/screens/admin/admin_products_screen.dart';
import 'package:nice_store/src/screens/admin/admin_users_screen.dart';
import 'package:nice_store/src/screens/cart_screen.dart';
import 'package:nice_store/src/screens/catalog_screen.dart';
import 'package:nice_store/src/screens/checkout_screen.dart';
import 'package:nice_store/src/screens/home_screen.dart';
import 'package:nice_store/src/screens/login_screen.dart';
import 'package:nice_store/src/screens/mobile_shell.dart';
import 'package:nice_store/src/screens/new_arrivals_screen.dart';
import 'package:nice_store/src/screens/product_detail_screen.dart';
import 'package:nice_store/src/screens/profile_screen.dart';
import 'package:nice_store/src/screens/register_screen.dart';
import 'package:nice_store/src/screens/shell_page.dart';
import 'package:nice_store/src/screens/web_shell.dart';

/// Produtos fixos (sem rede) usados nos testes.
class FakeProducts implements FakeStoreRepository {
  @override
  Future<List<Product>> fetchProducts() async => fallbackProducts;

  @override
  List<Product> get fallbackProducts => FakeStoreRepository().fallbackProducts;
}

class OfflineProducts extends ProductRepository {
  OfflineProducts(super.client, [this.products = const []]);

  final List<Product> products;

  @override
  Future<List<Product>> fetchAll() async => products;

  @override
  Future<Product?> fetchById(String id) async => products.where((p) => p.id == id).firstOrNull;
}

/// Auth sem eventos do Supabase (o estado vem de [TestProviders.user]).
class OfflineAuth extends AuthRepository {
  OfflineAuth(super.client);

  @override
  Stream<AuthState> get authChanges => const Stream.empty();
}

/// Árvore de providers igual à do main.dart, mas sem rede.
class TestProviders extends StatelessWidget {
  const TestProviders({super.key, required this.child, this.user, this.products = const []});

  final Widget child;

  /// Produtos "do Supabase" (vazio = usa o fallback da FakeStoreAPI).
  final List<Product> products;

  /// Usuário logado simulado (null = visitante).
  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final client = SupabaseClient(
      'http://127.0.0.1:9',
      'test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => OfflineAuth(client)),
        Provider<ProductRepository>(create: (_) => OfflineProducts(client, products)),
        Provider<FakeStoreRepository>(create: (_) => FakeProducts()),
        Provider(create: (_) => CartRepository(client)),
        Provider(create: (_) => OrderRepository(client)),
        Provider(create: (_) => StorageRepository(client)),
        Provider(create: (_) => AddressRepository(client)),
        Provider(create: (_) => UserRepository(client)),
        ChangeNotifierProvider(
          create: (c) {
            final auth = AuthController(c.read<AuthRepository>());
            if (user != null) auth.debugSignIn(user!);
            return auth;
          },
        ),
        ChangeNotifierProvider(
          create: (c) => CatalogController(c.read<ProductRepository>(), c.read<FakeStoreRepository>())..load(),
        ),
        ChangeNotifierProxyProvider<AuthController, CartController>(
          create: (c) => CartController(c.read<CartRepository>()),
          update: (_, auth, cart) => cart!..bindUser(auth.user?.id),
        ),
        ChangeNotifierProvider(create: (c) => OrderController(c.read<OrderRepository>())),
        ChangeNotifierProvider(
          create: (c) => AdminController(c.read<ProductRepository>(), c.read<StorageRepository>()),
        ),
        ChangeNotifierProxyProvider<AuthController, AddressController>(
          create: (c) => AddressController(c.read<AddressRepository>()),
          update: (_, auth, addresses) => addresses!..bindUser(auth.user?.id),
        ),
        ChangeNotifierProvider(
          create: (c) =>
              UserAdminController(c.read<UserRepository>(), c.read<AddressRepository>(), c.read<OrderRepository>()),
        ),
      ],
      child: child,
    );
  }
}

/// Roteador de teste com as telas reais, sem as guardas de login.
GoRouter testRouter(String initial, {required bool web}) => GoRouter(
  initialLocation: initial,
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          web ? WebShell(location: state.uri.path, child: child) : MobileShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const ShellPage(child: HomeScreen()),
        ),
        GoRoute(
          path: '/novidades',
          builder: (_, _) => const ShellPage(child: NewArrivalsScreen()),
        ),
        GoRoute(
          path: '/catalogo',
          builder: (_, state) => ShellPage(
            child: CatalogScreen(
              key: ValueKey(state.uri.toString()),
              initialCategory: state.uri.queryParameters['categoria'],
              initialQuery: state.uri.queryParameters['busca'],
              scrollToProducts: state.uri.queryParameters['secao'] == catalogProductsSection,
            ),
          ),
        ),
        GoRoute(
          path: '/sobre',
          builder: (_, _) => const ShellPage(child: AboutScreen()),
        ),
        GoRoute(
          path: '/carrinho',
          builder: (_, _) => const ShellPage(child: CartScreen()),
        ),
        GoRoute(
          path: '/produto/:id',
          builder: (_, state) => ShellPage(child: ProductDetailScreen(productId: state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/admin',
          builder: (_, _) => const ShellPage(child: AdminDashboardScreen()),
        ),
        GoRoute(
          path: '/admin/produtos',
          builder: (_, _) => const ShellPage(child: AdminProductsScreen()),
        ),
        GoRoute(
          path: '/admin/usuarios',
          builder: (_, _) => const ShellPage(child: AdminUsersScreen()),
        ),
        GoRoute(
          path: '/admin/produto/novo',
          builder: (_, _) => const ShellPage(child: AdminProductFormScreen()),
        ),
        GoRoute(
          path: '/admin/descontos',
          builder: (_, _) => const ShellPage(child: AdminDiscountsScreen()),
        ),
        GoRoute(
          path: '/checkout',
          builder: (_, _) => const ShellPage(child: CheckoutScreen()),
        ),
        GoRoute(
          path: '/perfil',
          builder: (_, _) => const ShellPage(child: ProfileScreen()),
        ),
      ],
    ),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/cadastro', builder: (_, _) => const RegisterScreen()),
  ],
);
