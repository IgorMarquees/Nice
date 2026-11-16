import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/nice_theme.dart';
import '../../widgets/responsive.dart';

class _AdminSection {
  const _AdminSection(this.title, this.description, this.icon, this.path);

  final String title;
  final String description;
  final IconData icon;
  final String path;
}

const _sections = [
  _AdminSection(
    'Produtos',
    'Lista, busca, destaque, novidade, desconto e exclusão de produtos.',
    Icons.inventory_2_outlined,
    '/admin/produtos',
  ),
  _AdminSection(
    'Cadastrar produto',
    'Novo produto com cores, fotos por cor, tamanhos e detalhes técnicos.',
    Icons.add_box_outlined,
    '/admin/produto/novo',
  ),
  _AdminSection(
    'Usuários',
    'Clientes cadastrados, endereços, histórico de pedidos e permissão de admin.',
    Icons.people_outline,
    '/admin/usuarios',
  ),
];

/// Página inicial do painel admin: um cartão para cada área.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ContentWrapper(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.isDesktop ? 48 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('NICE', style: text.labelMedium),
            const SizedBox(height: 4),
            Text('PAINEL ADMIN', style: text.headlineLarge),
            const SizedBox(height: 28),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900 ? 3 : (constraints.maxWidth >= 560 ? 2 : 1);
                final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final section in _sections) SizedBox(width: width, child: _AdminCard(section: section)),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.section});

  final _AdminSection section;

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
        onTap: () => context.push(section.path),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: NiceTheme.red,
                    child: Icon(section.icon, color: NiceTheme.white),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_outward, color: NiceTheme.red),
                ],
              ),
              const SizedBox(height: 20),
              Text(section.title.toUpperCase(), style: text.titleLarge),
              const SizedBox(height: 6),
              Text(section.description, style: text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
