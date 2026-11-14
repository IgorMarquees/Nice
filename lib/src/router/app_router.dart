import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';
import '../screens/about_screen.dart';
import '../screens/admin/admin_product_form_screen.dart';
import '../screens/admin/admin_products_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/catalog_screen.dart';
import '../screens/checkout_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/mobile_shell.dart';
import '../screens/new_arrivals_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/register_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/web_shell.dart';
import '../widgets/state_views.dart';

/// Rotas que exigem login (visitante é redirecionado para /login).
const _customerOnly = ['/carrinho', '/checkout', '/perfil'];

/// Rotas exclusivas do administrador.
const _adminOnly = ['/admin'];

GoRouter buildRouter(AuthController auth) {
  bool matches(String path, List<String> prefixes) => prefixes.any(path.startsWith);

  return GoRouter(
    refreshListenable: auth,
    errorBuilder: (context, state) => Scaffold(
      body: EmptyState(
        icon: Icons.search_off,
        title: 'Página não encontrada',
        actionLabel: 'Ir para a Home',
        onAction: () => context.go('/'),
      ),
    ),
    redirect: (context, state) {
      final path = state.matchedLocation;
      final protected = matches(path, _customerOnly) || matches(path, _adminOnly);
      final here = Uri.encodeComponent(state.uri.toString());

      // Sessão ainda sendo restaurada: não decide nada sobre rotas protegidas.
      if (auth.status == AuthStatus.loading) {
        return protected ? '/carregando?from=$here' : null;
      }
      if (path == '/carregando') return state.uri.queryParameters['from'] ?? '/';

      if (protected && !auth.isSignedIn) return '/login?from=$here';
      if (matches(path, _adminOnly) && !auth.isAdmin) return '/';
      if ((path == '/login' || path == '/cadastro') && auth.isSignedIn) {
        return state.uri.queryParameters['from'] ?? '/';
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => kIsWeb
            ? WebShell(location: state.uri.path, child: child)
            : MobileShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
          GoRoute(path: '/novidades', builder: (_, _) => const NewArrivalsScreen()),
          GoRoute(
            path: '/catalogo',
            builder: (_, state) => CatalogScreen(
              key: ValueKey(state.uri.toString()),
              initialCategory: state.uri.queryParameters['categoria'],
              initialQuery: state.uri.queryParameters['busca'],
            ),
          ),
          GoRoute(
            path: '/produto/:id',
            builder: (_, state) => ProductDetailScreen(
              key: ValueKey(state.pathParameters['id']),
              productId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(path: '/sobre', builder: (_, _) => const AboutScreen()),
          GoRoute(path: '/carrinho', builder: (_, _) => const CartScreen()),
          GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
          GoRoute(path: '/perfil', builder: (_, _) => const ProfileScreen()),
          GoRoute(path: '/admin', builder: (_, _) => const AdminProductsScreen()),
          GoRoute(path: '/admin/produto/novo', builder: (_, _) => const AdminProductFormScreen()),
          GoRoute(
            path: '/admin/produto/:id',
            builder: (_, state) => AdminProductFormScreen(
              key: ValueKey(state.pathParameters['id']),
              productId: state.pathParameters['id'],
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        builder: (_, state) => LoginScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: '/cadastro',
        builder: (_, state) => RegisterScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(path: '/carregando', builder: (_, _) => const SplashScreen()),
    ],
  );
}
