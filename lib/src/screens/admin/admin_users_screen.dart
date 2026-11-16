import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_admin_controller.dart';
import '../../models/app_user.dart';
import '../../theme/nice_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/responsive.dart';
import '../../widgets/state_views.dart';

/// Lista de usuários cadastrados (admin).
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<UserAdminController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final users = context.watch<UserAdminController>();
    final text = Theme.of(context).textTheme;

    return ContentWrapper(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.isDesktop ? 48 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('PAINEL ADMIN', style: text.labelMedium),
            const SizedBox(height: 4),
            Text('USUÁRIOS', style: text.headlineLarge),
            const SizedBox(height: 20),
            TextField(
              onChanged: users.search,
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou e-mail...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 20),
            if (users.loading)
              const LoadingView()
            else if (users.error != null)
              InlineMessage(text: users.error!)
            else if (users.items.isEmpty)
              const EmptyState(icon: Icons.people_outline, title: 'Nenhum usuário encontrado')
            else
              for (final user in users.items) ...[
                _UserTile(user: user),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: NiceTheme.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NiceTheme.radius),
        side: const BorderSide(color: NiceTheme.softGray, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/admin/usuarios/${user.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: user.isAdmin ? NiceTheme.red : NiceTheme.softGray,
                child: Icon(
                  user.isAdmin ? Icons.admin_panel_settings_outlined : Icons.person_outline,
                  color: user.isAdmin ? NiceTheme.white : NiceTheme.charcoal,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      [user.email, if (user.createdAt != null) 'desde ${formatDate(user.createdAt)}'].join(' · '),
                      style: text.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (user.isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  color: NiceTheme.charcoal,
                  child: Text('ADMIN', style: text.labelSmall?.copyWith(color: NiceTheme.white)),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
