import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../theme/nice_theme.dart';
import '../utils/navigation.dart';
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
  NavDestination('Catálogo', '/catalogo'),
  NavDestination('Sobre nós', '/sobre'),
];

bool _isActive(String location, String path) =>
    path == '/' ? location == '/' : location.startsWith(path);

/// Toda busca abre o Catálogo já rolado até os produtos.
void _search(BuildContext context, String value) => context.searchCatalog(value);

/// Cabeçalho do site: logo, menu horizontal, busca, carrinho e conta.
///
/// Larguras (antes havia overflow entre ~900 e ~1100 px):
/// - `>= 1240`: menu + campo de busca flexível + "Admin" com texto;
/// - `980–1240`: menu + ícone de busca; "Admin" só com ícone;
/// - `< 980`: logo, carrinho e menu lateral.
class WebNavbar extends StatelessWidget {
  const WebNavbar({super.key, required this.location});

  final String location;

  static const _menuBreakpoint = 980.0;
  static const _fullBreakpoint = 1240.0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final cartCount = context.watch<CartController>().itemCount;
    final width = context.screenWidth;
    final wide = width >= _menuBreakpoint;
    final full = width >= _fullBreakpoint;

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
                SizedBox(width: full ? 40 : 24),
                for (final item in webDestinations)
                  _NavLink(item: item, active: _isActive(location, item.path)),
                if (full) ...[
                  // A busca ocupa o espaço que sobrar (até 260 px), sem estourar a linha.
                  const SizedBox(width: 16),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: _SearchField(onSubmit: (v) => _search(context, v)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  const Spacer(),
                  IconButton(
                    tooltip: 'Buscar',
                    onPressed: () => context.searchCatalog(''),
                    icon: const Icon(Icons.search),
                  ),
                ],
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
              if (wide) ..._accountActions(context, auth, showLabel: full) else
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

  List<Widget> _accountActions(BuildContext context, AuthController auth, {required bool showLabel}) {
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
        showLabel
            ? TextButton.icon(
                onPressed: () => context.go('/admin'),
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                label: const Text('Admin'),
              )
            : IconButton(
                tooltip: 'Painel admin',
                color: NiceTheme.red,
                onPressed: () => context.go('/admin'),
                icon: const Icon(Icons.admin_panel_settings_outlined),
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
        margin: EdgeInsets.symmetric(horizontal: context.screenWidth >= WebNavbar._fullBreakpoint ? 14 : 10),
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
