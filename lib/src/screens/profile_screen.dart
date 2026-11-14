import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/order_controller.dart';
import '../models/order.dart';
import '../theme/nice_theme.dart';
import '../utils/formatters.dart';
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
                _OrderCard(order: order),
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(NiceTheme.radius),
        border: Border.all(color: NiceTheme.softGray, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Pedido #${order.shortId} · ${formatDate(order.createdAt)}', style: text.titleSmall),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: NiceTheme.red,
                child: Text(order.statusLabel.toUpperCase(), style: text.labelSmall?.copyWith(color: NiceTheme.white)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${item.quantity}x ${item.title}${item.size.isEmpty ? '' : ' (${item.size})'}',
                style: text.bodyMedium,
              ),
            ),
          const Divider(height: 24),
          Row(
            children: [
              Text(order.paymentMethod.label, style: text.bodySmall),
              const Spacer(),
              Text(formatCurrency(order.total), style: text.titleSmall),
            ],
          ),
        ],
      ),
    );
  }
}
