import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/admin_controller.dart';
import '../../controllers/catalog_controller.dart';
import '../../models/product.dart';
import '../../theme/nice_theme.dart';
import '../../utils/feedback.dart';
import '../../utils/formatters.dart';
import '../../widgets/discount_editor.dart';
import '../../widgets/nice_network_image.dart';
import '../../widgets/responsive.dart';
import '../../widgets/state_views.dart';

enum _StatusFilter {
  all('Todos'),
  withDiscount('Com desconto'),
  withoutDiscount('Sem desconto');

  const _StatusFilter(this.label);
  final String label;
}

/// Descontos em massa: seleciona vários produtos e aplica (com período) ou
/// cancela o desconto de todos de uma vez. Também edita/cancela um por um.
class AdminDiscountsScreen extends StatefulWidget {
  const AdminDiscountsScreen({super.key});

  @override
  State<AdminDiscountsScreen> createState() => _AdminDiscountsScreenState();
}

class _AdminDiscountsScreenState extends State<AdminDiscountsScreen> {
  final Set<String> _selected = {};
  String _query = '';
  String _category = CatalogController.allCategories;
  _StatusFilter _status = _StatusFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminController>().load();
    });
  }

  List<Product> _visible(List<Product> all) {
    final q = _query.trim().toLowerCase();
    return all.where((p) {
      final status = p.discountStatus;
      final configured = status == DiscountStatus.active || status == DiscountStatus.scheduled;
      return (q.isEmpty || p.title.toLowerCase().contains(q)) &&
          (_category == CatalogController.allCategories || p.category == _category) &&
          switch (_status) {
            _StatusFilter.all => true,
            _StatusFilter.withDiscount => configured,
            _StatusFilter.withoutDiscount => !configured,
          };
    }).toList();
  }

  Future<void> _apply(List<String> ids, {Product? single}) async {
    final admin = context.read<AdminController>();
    final catalog = context.read<CatalogController>();
    final input = await showDiscountDialog(
      context,
      title: single == null ? 'Desconto em ${ids.length} produto(s)' : 'Desconto: ${single.title}',
      initialPercent: single != null && single.discountPercent > 0 ? single.discountPercent : 10,
      startsAt: single?.discountStartsAt,
      endsAt: single?.discountEndsAt,
    );
    if (input == null || !mounted) return;
    final ok = await admin.applyDiscount(ids, percent: input.percent, startsAt: input.startsAt, endsAt: input.endsAt);
    if (!mounted) return;
    if (ok) {
      catalog.load(force: true);
      setState(_selected.clear);
    }
    showMessage(context, ok ? 'Desconto aplicado em ${ids.length} produto(s).' : (admin.error ?? 'Erro.'));
  }

  Future<void> _cancel(List<String> ids) async {
    final admin = context.read<AdminController>();
    final catalog = context.read<CatalogController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar desconto'),
        content: Text('Remover o desconto de ${ids.length} produto(s)? Eles voltam ao preço cheio na hora.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Voltar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancelar desconto')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await admin.cancelDiscount(ids);
    if (!mounted) return;
    if (ok) {
      catalog.load(force: true);
      setState(_selected.clear);
    }
    showMessage(context, ok ? 'Desconto cancelado em ${ids.length} produto(s).' : (admin.error ?? 'Erro.'));
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminController>();
    final text = Theme.of(context).textTheme;
    final visible = _visible(admin.all);
    final visibleIds = visible.map((p) => p.id).toSet();
    // Seleção só conta produtos que ainda existem na lista.
    _selected.removeWhere((id) => !admin.all.any((p) => p.id == id));
    final allVisibleSelected = visible.isNotEmpty && visibleIds.every(_selected.contains);
    final selected = _selected.toList();

    return ContentWrapper(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.isDesktop ? 48 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('PAINEL ADMIN', style: text.labelMedium),
            const SizedBox(height: 4),
            Text('DESCONTOS', style: text.headlineLarge),
            const SizedBox(height: 6),
            Text(
              'Selecione os produtos e aplique um desconto com data e hora de início e fim, ou cancele os descontos de vários de uma vez.',
              style: text.bodySmall,
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(hintText: 'Buscar produto...', prefixIcon: Icon(Icons.search)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final category in CatalogController.categories)
                  ChoiceChip(
                    label: Text(category),
                    selected: _category == category,
                    labelStyle: NiceTheme.chipLabel(selected: _category == category),
                    onSelected: (_) => setState(() => _category = category),
                  ),
                const SizedBox(width: 8),
                for (final filter in _StatusFilter.values)
                  ChoiceChip(
                    label: Text(filter.label),
                    selected: _status == filter,
                    labelStyle: NiceTheme.chipLabel(selected: _status == filter),
                    onSelected: (_) => setState(() => _status = filter),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Barra de ações em massa.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: NiceTheme.lightGray,
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    // Cabe em telas de 320 px: o texto quebra em vez de estourar.
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: allVisibleSelected,
                          onChanged: visible.isEmpty
                              ? null
                              : (v) => setState(() {
                                  v == true ? _selected.addAll(visibleIds) : _selected.removeAll(visibleIds);
                                }),
                        ),
                        Flexible(child: Text('Todos (${visible.length})', style: text.bodyMedium)),
                      ],
                    ),
                  ),
                  Text('${selected.length} selecionado(s)', style: text.titleSmall),
                  FilledButton.icon(
                    onPressed: selected.isEmpty || admin.saving ? null : () => _apply(selected),
                    icon: const Icon(Icons.local_offer_outlined, size: 18),
                    label: const Text('APLICAR DESCONTO'),
                  ),
                  OutlinedButton.icon(
                    onPressed: selected.isEmpty || admin.saving ? null : () => _cancel(selected),
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('CANCELAR DESCONTO'),
                  ),
                  if (admin.saving)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (admin.loading && admin.all.isEmpty)
              const LoadingView()
            else if (admin.error != null && admin.all.isEmpty)
              InlineMessage(text: admin.error!)
            else if (visible.isEmpty)
              const EmptyState(icon: Icons.local_offer_outlined, title: 'Nenhum produto encontrado')
            else
              for (final product in visible) ...[
                _DiscountTile(
                  product: product,
                  selected: _selected.contains(product.id),
                  onSelected: (v) => setState(() => v ? _selected.add(product.id) : _selected.remove(product.id)),
                  onEdit: () => _apply([product.id], single: product),
                  onCancel: () => _cancel([product.id]),
                ),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DiscountTile extends StatelessWidget {
  const _DiscountTile({
    required this.product,
    required this.selected,
    required this.onSelected,
    required this.onEdit,
    required this.onCancel,
  });

  final Product product;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final status = product.discountStatus;
    final cancellable = status == DiscountStatus.active || status == DiscountStatus.scheduled;
    final discounted = product.discountPercent > 0
        ? product.price * (100 - product.discountPercent) / 100
        : product.price;

    return Material(
      color: selected ? NiceTheme.lightGray : NiceTheme.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NiceTheme.radius),
        side: BorderSide(color: selected ? NiceTheme.red : NiceTheme.softGray, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(NiceTheme.radius),
        onTap: () => onSelected(!selected),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
          child: Row(
            children: [
              Checkbox(value: selected, onChanged: (v) => onSelected(v ?? false)),
              SizedBox(
                width: 52,
                height: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(NiceTheme.radius),
                  child: ColoredBox(
                    color: NiceTheme.softGray,
                    child: NiceNetworkImage(url: product.imageUrl),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      product.discountPercent > 0 && status != DiscountStatus.expired
                          ? '${formatCurrency(product.price)} → ${formatCurrency(discounted)}'
                          : formatCurrency(product.price),
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        DiscountStatusChip(status: status),
                        if (status != DiscountStatus.none) Text(describeDiscount(product), style: text.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: cancellable ? 'Editar desconto' : 'Aplicar desconto',
                icon: const Icon(Icons.local_offer_outlined),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Cancelar desconto',
                icon: const Icon(Icons.block),
                onPressed: cancellable ? onCancel : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
