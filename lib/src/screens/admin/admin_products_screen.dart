import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../controllers/catalog_controller.dart';
import '../../models/product.dart';
import '../../theme/nice_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/nice_network_image.dart';
import '../../widgets/responsive.dart';
import '../../widgets/state_views.dart';

/// Painel do administrador: lista, busca, exclusão e chaves de
/// Destaque (Home) / Novidade (página Novidades).
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminController>().load();
    });
  }

  Future<void> _setFlag(Product product, {bool? isFeatured, bool? isNew}) async {
    final admin = context.read<AdminController>();
    final catalog = context.read<CatalogController>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await admin.setFlags(product, isFeatured: isFeatured, isNew: isNew);
    if (ok) {
      catalog.load(force: true);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(admin.error ?? 'Erro ao atualizar.')));
    }
  }

  Future<void> _delete(Product product) async {
    final admin = context.read<AdminController>();
    final catalog = context.read<CatalogController>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir produto'),
        content: Text('Deseja excluir "${product.title}"? Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await admin.delete(product);
    if (ok) {
      catalog.load(force: true);
      messenger.showSnackBar(const SnackBar(content: Text('Produto excluído.')));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(admin.error ?? 'Erro ao excluir.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminController>();
    final text = Theme.of(context).textTheme;

    return ContentWrapper(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.isDesktop ? 48 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PAINEL ADMIN', style: text.labelMedium),
                      const SizedBox(height: 4),
                      Text('PRODUTOS', style: text.headlineLarge),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.push('/admin/produto/novo'),
                  icon: const Icon(Icons.add),
                  label: Text(context.isCompact ? 'NOVO' : 'NOVO PRODUTO'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: admin.search,
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou categoria...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 20),
            if (admin.loading)
              const LoadingView()
            else if (admin.error != null && admin.items.isEmpty)
              InlineMessage(text: admin.error!)
            else if (admin.items.isEmpty)
              const EmptyState(icon: Icons.inventory_2_outlined, title: 'Nenhum produto cadastrado')
            else
              for (final product in admin.items) ...[
                _AdminTile(
                  product: product,
                  onFeatured: (v) => _setFlag(product, isFeatured: v),
                  onNew: (v) => _setFlag(product, isNew: v),
                  onEdit: () => context.push('/admin/produto/${product.id}'),
                  onDelete: () => _delete(product),
                ),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.product,
    required this.onFeatured,
    required this.onNew,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final ValueChanged<bool> onFeatured;
  final ValueChanged<bool> onNew;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final switches = Wrap(
      spacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _LabeledSwitch(label: 'Destaque', value: product.isFeatured, onChanged: onFeatured),
        _LabeledSwitch(label: 'Novidade', value: product.isNew, onChanged: onNew),
      ],
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.title, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(
          '${product.category} · ${formatCurrency(product.price)} · estoque ${product.stock}',
          style: text.bodySmall,
        ),
        if (context.isCompact) ...[const SizedBox(height: 8), switches],
      ],
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(NiceTheme.radius),
        border: Border.all(color: NiceTheme.softGray, width: 1.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 76,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(NiceTheme.radius),
              child: ColoredBox(color: NiceTheme.softGray, child: NiceNetworkImage(url: product.imageUrl)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: info),
          if (!context.isCompact) ...[switches, const SizedBox(width: 8)],
          IconButton(tooltip: 'Editar', icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
          IconButton(tooltip: 'Excluir', icon: const Icon(Icons.delete_outline), onPressed: onDelete),
        ],
      ),
    );
  }
}

class _LabeledSwitch extends StatelessWidget {
  const _LabeledSwitch({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(width: 6),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
