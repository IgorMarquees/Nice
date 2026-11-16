import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/address_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/order_controller.dart';
import '../models/order.dart';
import '../theme/nice_theme.dart';
import '../widgets/address_form.dart';
import '../widgets/order_card.dart';
import '../widgets/responsive.dart';
import '../widgets/state_views.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.read<AuthController>().user?.id;
      if (userId != null) context.read<OrderController>().loadMine(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final orders = context.watch<OrderController>();
    final text = Theme.of(context).textTheme;
    final user = auth.user;
    if (user == null) return const LoadingView();

    return ContentWrapper(
      maxWidth: 900,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.isDesktop ? 48 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('PERFIL', style: text.headlineLarge),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NiceTheme.lightGray,
                borderRadius: BorderRadius.circular(NiceTheme.radius),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: NiceTheme.red,
                    child: Icon(Icons.person, color: NiceTheme.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: text.titleLarge),
                        Text(user.email, style: text.bodySmall),
                      ],
                    ),
                  ),
                  if (user.isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      color: NiceTheme.charcoal,
                      child: Text('ADMIN', style: text.labelSmall?.copyWith(color: NiceTheme.white)),
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
            const SizedBox(height: 36),
            _AddressesSection(recipient: user.name),
            const SizedBox(height: 36),
            Text('MEUS PEDIDOS', style: text.headlineSmall),
            const SizedBox(height: 16),
            if (orders.loading)
              const LoadingView()
            else if (orders.error != null)
              InlineMessage(text: orders.error!)
            else if (orders.orders.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Você ainda não fez pedidos',
              )
            else
              for (final order in orders.orders) ...[
                OrderCard(order: order),
                const SizedBox(height: 14),
              ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: auth.signOut,
              icon: const Icon(Icons.logout),
              label: const Text('SAIR'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _AddressesSection extends StatelessWidget {
  const _AddressesSection({required this.recipient});

  final String recipient;

  Future<void> _delete(BuildContext context, SavedAddress address) async {
    final controller = context.read<AddressController>();
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
    final addresses = context.watch<AddressController>();
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('MEUS ENDEREÇOS', style: text.headlineSmall)),
            TextButton.icon(
              onPressed: () => showAddressDialog(context, recipient: recipient),
              icon: const Icon(Icons.add_location_alt_outlined, size: 18),
              label: const Text('Adicionar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (addresses.loading && addresses.items.isEmpty)
          const LinearProgressIndicator()
        else if (addresses.items.isEmpty)
          Text(
            'Nenhum endereço salvo. Salve um endereço para preencher a entrega automaticamente na finalização da compra.',
            style: text.bodySmall,
          )
        else
          for (final address in addresses.items) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(NiceTheme.radius),
                border: Border.all(color: NiceTheme.softGray, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: NiceTheme.red),
                  const SizedBox(width: 12),
                  Expanded(child: AddressSummary(address: address.address, title: address.title)),
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => showAddressDialog(context, initial: address),
                  ),
                  IconButton(
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(context, address),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}
