import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/user_admin_controller.dart';
import '../../models/app_user.dart';
import '../../theme/nice_theme.dart';
import '../../utils/feedback.dart';
import '../../utils/formatters.dart';
import '../../widgets/address_form.dart';
import '../../widgets/order_card.dart';
import '../../widgets/responsive.dart';
import '../../widgets/state_views.dart';

/// Detalhe de um usuário: dados, endereços, pedidos e permissão de admin.
class AdminUserDetailScreen extends StatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  UserDetails? _details;
  bool _loading = true;
  bool _changingRole = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final details = await context.read<UserAdminController>().details(widget.userId);
    if (!mounted) return;
    setState(() {
      _details = details;
      _loading = false;
    });
  }

  Future<void> _toggleRole(AppUser user) async {
    final makeAdmin = !user.isAdmin;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(makeAdmin ? 'Tornar administrador' : 'Remover administrador'),
        content: Text(
          makeAdmin
              ? '${user.name} poderá cadastrar produtos, ver estoque e gerenciar usuários. Continuar?'
              : '${user.name} voltará a ser um cliente comum. Continuar?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _changingRole = true);
    final role = makeAdmin ? UserRole.admin : UserRole.customer;
    final error = await context.read<UserAdminController>().setRole(user, role);
    if (!mounted) return;
    setState(() {
      _changingRole = false;
      if (error == null) _details = _details?.copyWith(user: user.copyWith(role: role));
    });
    showMessage(context, error ?? (makeAdmin ? 'Usuário agora é administrador.' : 'Usuário agora é cliente.'));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    final details = _details;
    if (details == null) {
      return EmptyState(
        icon: Icons.person_off_outlined,
        title: 'Usuário não encontrado',
        actionLabel: 'Voltar',
        onAction: () => context.go('/admin/usuarios'),
      );
    }

    final text = Theme.of(context).textTheme;
    final user = details.user;
    final isMe = context.watch<AuthController>().user?.id == user.id;

    return ContentWrapper(
      maxWidth: 900,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.isDesktop ? 48 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('PAINEL ADMIN / USUÁRIOS', style: text.labelMedium),
            const SizedBox(height: 4),
            Text(user.name.toUpperCase(), style: text.headlineLarge),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NiceTheme.lightGray,
                borderRadius: BorderRadius.circular(NiceTheme.radius),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(user.email, style: text.titleSmall),
                      Text(
                        'Perfil: ${user.isAdmin ? 'Administrador' : 'Cliente'}'
                        '${user.createdAt == null ? '' : ' · cadastro em ${formatDate(user.createdAt)}'}',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                  if (!isMe)
                    FilledButton.icon(
                      onPressed: _changingRole ? null : () => _toggleRole(user),
                      icon: Icon(user.isAdmin ? Icons.remove_moderator_outlined : Icons.add_moderator_outlined),
                      label: Text(user.isAdmin ? 'REMOVER ADMIN' : 'TORNAR ADMIN'),
                    )
                  else
                    Text('Esta é a sua conta', style: text.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('ENDEREÇOS CADASTRADOS', style: text.headlineSmall),
            const SizedBox(height: 12),
            if (details.addresses.isEmpty)
              Text('Nenhum endereço salvo.', style: text.bodySmall)
            else
              for (final address in details.addresses) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(NiceTheme.radius),
                    border: Border.all(color: NiceTheme.softGray, width: 1.5),
                  ),
                  child: AddressSummary(address: address.address, title: address.title),
                ),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 32),
            Text('HISTÓRICO DE PEDIDOS (${details.orders.length})', style: text.headlineSmall),
            const SizedBox(height: 12),
            if (details.orders.isEmpty)
              Text('Nenhum pedido realizado.', style: text.bodySmall)
            else
              for (final order in details.orders) ...[
                OrderCard(order: order),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
