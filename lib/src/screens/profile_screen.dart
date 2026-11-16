import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/address_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/order_controller.dart';
import '../models/app_user.dart';
import '../models/order.dart';
import '../theme/nice_theme.dart';
import '../utils/navigation.dart';
import '../widgets/address_form.dart';
import '../widgets/order_card.dart';
import '../widgets/responsive.dart';
import '../widgets/returns_policy.dart';
import '../widgets/social_links.dart';
import '../widgets/state_views.dart';

enum _Section { orders, addresses, returns }

/// Minha conta. Desktop: menu lateral (dados, atalhos, admin, sair) +
/// seções em cartões. Celular/tablet: cabeçalho, atalhos e seções empilhadas.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _keys = {for (final s in _Section.values) s: GlobalKey()};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.read<AuthController>().user?.id;
      if (userId != null) context.read<OrderController>().loadMine(userId);
    });
  }

  void _goTo(_Section section) {
    final target = _keys[section]!.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final orders = context.watch<OrderController>();
    final addresses = context.watch<AddressController>();
    final text = Theme.of(context).textTheme;
    final user = auth.user;
    if (user == null) return const LoadingView();
    final desktop = context.isDesktop;

    final sections = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          key: _keys[_Section.orders],
          icon: Icons.receipt_long_outlined,
          title: 'Meus pedidos',
          trailing: orders.orders.isEmpty ? null : Text('${orders.orders.length}', style: text.titleSmall),
          child: _OrdersList(controller: orders),
        ),
        const SizedBox(height: 20),
        _SectionCard(
          key: _keys[_Section.addresses],
          icon: Icons.location_on_outlined,
          title: 'Meus endereços',
          trailing: TextButton.icon(
            onPressed: () => showAddressDialog(context, recipient: user.name),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar'),
          ),
          child: _AddressesList(controller: addresses, recipient: user.name),
        ),
        const SizedBox(height: 20),
        _SectionCard(
          key: _keys[_Section.returns],
          icon: Icons.autorenew,
          title: 'Trocas e devoluções',
          child: const ReturnsPolicy(),
        ),
      ],
    );

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Minha conta', style: NiceTheme.sectionEyebrow(large: desktop)),
        const SizedBox(height: 6),
        Text('OLÁ, ${user.name.split(' ').first.toUpperCase()}', style: NiceTheme.sectionTitle(large: desktop)),
      ],
    );

    if (desktop) {
      return ContentWrapper(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 300,
                    child: _Sidebar(
                      user: user,
                      orderCount: orders.orders.length,
                      onNavigate: _goTo,
                      onSignOut: auth.signOut,
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(child: sections),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return ContentWrapper(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            title,
            const SizedBox(height: 20),
            _UserCard(user: user),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in _menu)
                  ActionChip(
                    avatar: Icon(item.icon, size: 18, color: NiceTheme.red),
                    label: Text(item.label),
                    onPressed: () => _goTo(item.section),
                  ),
              ],
            ),
            if (user.isAdmin) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/admin'),
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('PAINEL ADMINISTRATIVO'),
              ),
            ],
            const SizedBox(height: 24),
            sections,
            const SizedBox(height: 24),
            const _FollowUs(),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: auth.signOut, icon: const Icon(Icons.logout), label: const Text('SAIR')),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.section, this.icon, this.label);
  final _Section section;
  final IconData icon;
  final String label;
}

const _menu = [
  _MenuItem(_Section.orders, Icons.receipt_long_outlined, 'Meus pedidos'),
  _MenuItem(_Section.addresses, Icons.location_on_outlined, 'Meus endereços'),
  _MenuItem(_Section.returns, Icons.autorenew, 'Trocas e devoluções'),
];

/// Cartão de seção: ícone + título (+ ação) e o conteúdo.
class _SectionCard extends StatelessWidget {
  const _SectionCard({super.key, required this.icon, required this.title, required this.child, this.trailing});

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Material (e não Container com cor): os ListTile/ExpansionTile internos
    // precisam dele para mostrar o efeito de toque.
    return Material(
      color: NiceTheme.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NiceTheme.radius),
        side: const BorderSide(color: NiceTheme.softGray, width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.isCompact ? 18 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: NiceTheme.red),
                const SizedBox(width: 10),
                Expanded(child: Text(title.toUpperCase(), style: text.titleLarge)),
                ?trailing,
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

/// Avatar com iniciais, nome, e-mail e selo de admin.
class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final AppUser user;

  String get _initials {
    final parts = user.name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'N';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      color: NiceTheme.black,
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: NiceTheme.brightRed,
            child: Text(_initials, style: text.titleMedium?.copyWith(color: NiceTheme.white)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: text.titleLarge?.copyWith(color: NiceTheme.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: text.bodySmall?.copyWith(color: NiceTheme.midGray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (user.isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: NiceTheme.brightRed,
              child: Text('ADMIN', style: NiceTheme.badge()),
            ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.user, required this.orderCount, required this.onNavigate, required this.onSignOut});

  final AppUser user;
  final int orderCount;
  final ValueChanged<_Section> onNavigate;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _UserCard(user: user),
        Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: NiceTheme.softGray, width: 1.5),
              right: BorderSide(color: NiceTheme.softGray, width: 1.5),
              bottom: BorderSide(color: NiceTheme.softGray, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              for (final item in _menu)
                ListTile(
                  leading: Icon(item.icon, color: NiceTheme.red),
                  title: Text(item.label, style: text.titleSmall),
                  trailing: item.section == _Section.orders && orderCount > 0
                      ? Text('$orderCount', style: text.bodySmall)
                      : const Icon(Icons.chevron_right, size: 20),
                  onTap: () => onNavigate(item.section),
                ),
            ],
          ),
        ),
        if (user.isAdmin) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.go('/admin'),
            icon: const Icon(Icons.admin_panel_settings_outlined),
            label: const Text('PAINEL ADMINISTRATIVO'),
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: onSignOut, icon: const Icon(Icons.logout), label: const Text('SAIR')),
        const SizedBox(height: 28),
        const _FollowUs(),
      ],
    );
  }
}

class _FollowUs extends StatelessWidget {
  const _FollowUs();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SIGA A NICE', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        const SocialLinks(),
      ],
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({required this.controller});

  final OrderController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.loading) return const LoadingView();
    if (controller.error != null) return InlineMessage(text: controller.error!);
    if (controller.orders.isEmpty) {
      return _EmptyBlock(
        icon: Icons.shopping_bag_outlined,
        message: 'Você ainda não fez pedidos.',
        actionLabel: 'VER CATÁLOGO',
        onAction: () => context.go(catalogPath(toProducts: true)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final order in controller.orders) ...[OrderCard(order: order), const SizedBox(height: 12)],
      ],
    );
  }
}

/// Lista de endereços. Sempre aparece, mesmo sem endereço salvo, para o
/// cliente cadastrar antes da primeira compra.
class _AddressesList extends StatelessWidget {
  const _AddressesList({required this.controller, required this.recipient});

  final AddressController controller;
  final String recipient;

  Future<void> _delete(BuildContext context, SavedAddress address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir endereço'),
        content: Text('Deseja excluir "${address.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed == true) await controller.delete(address);
  }

  @override
  Widget build(BuildContext context) {
    if (controller.loading && controller.items.isEmpty) return const LinearProgressIndicator();
    if (controller.items.isEmpty) {
      return _EmptyBlock(
        icon: Icons.add_location_alt_outlined,
        message:
            controller.error ??
            'Nenhum endereço salvo. Cadastre um para preencher a entrega automaticamente na finalização da compra.',
        actionLabel: 'CADASTRAR ENDEREÇO',
        onAction: () => showAddressDialog(context, recipient: recipient),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final address in controller.items)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
                  decoration: BoxDecoration(
                    color: NiceTheme.lightGray,
                    borderRadius: BorderRadius.circular(NiceTheme.radius),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AddressSummary(address: address.address, title: address.title),
                      ),
                      IconButton(
                        tooltip: 'Editar',
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => showAddressDialog(context, initial: address),
                      ),
                      IconButton(
                        tooltip: 'Excluir',
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _delete(context, address),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.icon, required this.message, required this.actionLabel, required this.onAction});

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: NiceTheme.lightGray, borderRadius: BorderRadius.circular(NiceTheme.radius)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: NiceTheme.midGray),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: Theme.of(context).textTheme.bodyMedium)),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
