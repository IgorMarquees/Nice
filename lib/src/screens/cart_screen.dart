import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/cart_controller.dart';
import '../models/cart_item.dart';
import '../theme/nice_theme.dart';
import '../utils/formatters.dart';
import '../widgets/nice_network_image.dart';
import '../widgets/responsive.dart';
import '../widgets/state_views.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final text = Theme.of(context).textTheme;

    if (cart.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'Seu carrinho está vazio',
        message: 'Adicione peças pela Home ou pelo catálogo.',
        actionLabel: 'Ver catálogo',
        onAction: () => context.go('/catalogo'),
      );
    }

    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('CARRINHO', style: text.headlineLarge)),
            TextButton(onPressed: cart.clear, child: const Text('Limpar')),
          ],
        ),
        const SizedBox(height: 16),
        for (final item in cart.items) ...[
          _CartTile(item: item),
          const SizedBox(height: 14),
        ],
      ],
    );
    const summary = _OrderSummary();

    return ContentWrapper(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.isDesktop ? 48 : 8),
        child: context.isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: list),
                  const SizedBox(width: 40),
                  const SizedBox(width: 380, child: summary),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [list, summary, const SizedBox(height: 32)],
              ),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NiceTheme.white,
        borderRadius: BorderRadius.circular(NiceTheme.radius),
        border: Border.all(color: NiceTheme.softGray, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('RESUMO DO PEDIDO', style: text.titleLarge),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('Itens (${cart.itemCount})', style: text.bodyMedium),
              const Spacer(),
              Text(formatCurrency(cart.total), style: text.bodyMedium),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              Text('Total', style: text.titleLarge),
              const Spacer(),
              Text(formatCurrency(cart.total), style: text.headlineSmall?.copyWith(color: NiceTheme.red)),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.go('/checkout'),
            icon: const Icon(Icons.lock_outline),
            label: const Text('FINALIZAR COMPRA'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/catalogo'),
            child: const Text('Continuar comprando'),
          ),
        ],
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartController>();
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NiceTheme.lightGray,
        borderRadius: BorderRadius.circular(NiceTheme.radius),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(NiceTheme.radius),
              child: ColoredBox(color: NiceTheme.softGray, child: NiceNetworkImage(url: item.imageUrl)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: text.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (item.size.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Variação: ${item.size}', style: text.bodySmall),
                ],
                const SizedBox(height: 4),
                Text('${formatCurrency(item.unitPrice)} un.', style: text.bodySmall),
                const SizedBox(height: 8),
                Text(formatCurrency(item.subtotal), style: text.titleSmall),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: 'Remover',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => cart.remove(item),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Diminuir',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => cart.decrease(item),
                  ),
                  Text('${item.quantity}', style: text.titleSmall),
                  IconButton(
                    tooltip: 'Aumentar',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => cart.increase(item),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
