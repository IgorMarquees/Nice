import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/cart_controller.dart';
import '../theme/nice_theme.dart';
import '../widgets/nice_logo.dart';

/// Estrutura do app (Android e iOS idênticos): logo no topo e barra
/// inferior vermelha com botão de busca/catálogo no centro.
class MobileShell extends StatelessWidget {
  const MobileShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  // 0 Home | 1 Novidades | 3 Bag | 4 Perfil (2 = botão central)
  int get _index {
    if (location == '/') return 0;
    if (location.startsWith('/novidades')) return 1;
    if (location.startsWith('/catalogo')) return 2;
    if (location.startsWith('/carrinho') || location.startsWith('/checkout')) return 3;
    if (location.startsWith('/perfil') || location.startsWith('/admin')) return 4;
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartController>().itemCount;
    final index = _index;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            key: ValueKey(location),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(canGoBack: context.canPop()),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Buscar',
        onPressed: () => context.go('/catalogo'),
        backgroundColor: NiceTheme.red,
        foregroundColor: NiceTheme.white,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.search, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        height: 72,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Home',
              selected: index == 0,
              onTap: () => context.go('/'),
            ),
            _NavItem(
              icon: Icons.new_releases_outlined,
              selectedIcon: Icons.new_releases,
              label: 'Novidades',
              selected: index == 1,
              onTap: () => context.go('/novidades'),
            ),
            const SizedBox(width: 72), // espaço do botão central
            _NavItem(
              icon: Icons.shopping_bag_outlined,
              selectedIcon: Icons.shopping_bag,
              label: 'Bag',
              selected: index == 3,
              badgeCount: cartCount,
              onTap: () => context.go('/carrinho'),
            ),
            _NavItem(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Perfil',
              selected: index == 4,
              onTap: () => context.go('/perfil'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.canGoBack});

  final bool canGoBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const NiceLogo(compact: true),
          if (canGoBack)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Voltar',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = selected ? NiceTheme.white : NiceTheme.softGray;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
        );

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: badgeCount > 0,
              label: Text('$badgeCount'),
              backgroundColor: NiceTheme.white,
              textColor: NiceTheme.red,
              child: Icon(selected ? selectedIcon : icon, color: color, size: 26),
            ),
            const SizedBox(height: 4),
            Text(label, style: style),
          ],
        ),
      ),
    );
  }
}
