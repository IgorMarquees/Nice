import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../theme/nice_theme.dart';
import 'nice_logo.dart';
import 'responsive.dart';

class NavDestination {
  const NavDestination(this.label, this.path);
  final String label;
  final String path;
}

const webDestinations = [
  NavDestination('Home', '/'),
  NavDestination('Novidades', '/novidades'),
  NavDestination('Categorias', '/catalogo'),
  NavDestination('Sobre nós', '/sobre'),
];

bool _isActive(String location, String path) =>
    path == '/' ? location == '/' : location.startsWith(path);

void _search(BuildContext context, String value) {
  final query = value.trim();
  context.go(query.isEmpty ? '/catalogo' : '/catalogo?busca=${Uri.encodeQueryComponent(query)}');
}

/// Cabeçalho do site: logo, menu horizontal, busca, carrinho e conta.
class WebNavbar extends StatelessWidget {
  const WebNavbar({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final cartCount = context.watch<CartController>().itemCount;
    final wide = context.screenWidth >= 900;

    return Material(
      color: NiceTheme.white,
      elevation: 0,
      child: Container(
        height: 72,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: NiceTheme.softGray)),
        ),
        child: ContentWrapper(
          child: Row(
            children: [
              InkWell(
                onTap: () => context.go('/'),
                child: const NiceLogo(compact: true),
              ),
              if (wide) ...[
                const SizedBox(width: 40),
                for (final item in webDestinations)
                  _NavLink(item: item, active: _isActive(location, item.path)),
                const Spacer(),
                SizedBox(width: 280, child: _SearchField(onSubmit: (v) => _search(context, v))),
                const SizedBox(width: 8),
              ] else
                const Spacer(),
              IconButton(
                tooltip: 'Carrinho',
                onPressed: () => context.go('/carrinho'),
                icon: Badge(
                  isLabelVisible: cartCount > 0,
                  label: Text('$cartCount'),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
              ),
              if (wide) ..._accountActions(context, auth) else
                Builder(
                  builder: (context) => IconButton(
                    tooltip: 'Menu',
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                    icon: const Icon(Icons.menu),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _accountActions(BuildContext context, AuthController auth) {
    if (!auth.isSignedIn) {
      return [
        IconButton(
          tooltip: 'Entrar',
          onPressed: () => context.go('/login'),
          icon: const Icon(Icons.person_outline),
        ),
      ];
    }
    return [
      if (auth.isAdmin)
        TextButton.icon(
          onPressed: () => context.go('/admin'),
          icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
          label: const Text('Admin'),
        ),
      IconButton(
        tooltip: 'Minha conta',
        onPressed: () => context.go('/perfil'),
        icon: const Icon(Icons.person),
      ),
    ];
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.item, required this.active});

  final NavDestination item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => context.go(item.path),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: active ? NiceTheme.red : NiceTheme.transparent, width: 2),
          ),
        ),
        child: Text(item.label, style: text.labelLarge),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmit,
      decoration: const InputDecoration(
        hintText: 'Encontre seu drip...',
        isDense: true,
        prefixIcon: Icon(Icons.search, color: NiceTheme.red),
      ),
    );
  }
}

/// Menu lateral usado na Web em telas estreitas.
class WebNavDrawer extends StatelessWidget {
  const WebNavDrawer({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    void open(String path) {
      Navigator.of(context).pop();
      context.go(path);
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Align(alignment: Alignment.centerLeft, child: NiceLogo(compact: true)),
            const SizedBox(height: 20),
            _SearchField(
              onSubmit: (v) {
                Navigator.of(context).pop();
                _search(context, v);
              },
            ),
            const SizedBox(height: 12),
            for (final item in webDestinations)
              ListTile(
                selected: _isActive(location, item.path),
                selectedColor: NiceTheme.red,
                title: Text(item.label),
                onTap: () => open(item.path),
              ),
            const Divider(),
            if (!auth.isSignedIn)
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Entrar'),
                onTap: () => open('/login'),
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Minha conta'),
                onTap: () => open('/perfil'),
              ),
              if (auth.isAdmin)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Painel admin'),
                  onTap: () => open('/admin'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
