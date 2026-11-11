import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../cart/cart_controller.dart';
import '../cart/cart_item.dart';
import '../database/firestore_user_data_repository.dart';
import '../theme/nice_theme.dart';
import '../widgets/nice_logo.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 14),
          const NiceLogo(compact: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
            child: Row(
              children: [
                Text('Carrinho', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const Spacer(),
                if (cart.items.isNotEmpty) TextButton(onPressed: cart.clear, child: const Text('Limpar')),
              ],
            ),
          ),
          Expanded(
            child: cart.items.isEmpty
                ? const Center(
                    child: Text(
                      'Seu carrinho esta vazio.\nAdicione pecas pela Home ou Buscar.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) => _CartTile(item: cart.items[index]),
                  ),
          ),
          if (cart.items.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -8)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      const Spacer(),
                      Text(_currency(cart.total), style: const TextStyle(color: NiceTheme.red, fontWeight: FontWeight.w900, fontSize: 22)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Finalizar compra'),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final userId = context.read<AuthController>().user?.id;
                        if (userId == null) return;

                        try {
                          await context
                              .read<FirestoreUserDataRepository>()
                              .createOrder(
                                userId: userId,
                                items: cart.items,
                                total: cart.total,
                              );
                          cart.clear();
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Pedido salvo com sucesso.')),
                          );
                        } catch (_) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Nao foi possivel finalizar a compra.')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NiceTheme.softGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.product.imageUrl,
              width: 72,
              height: 86,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(Icons.checkroom, size: 48),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.title, style: const TextStyle(fontWeight: FontWeight.w900, color: NiceTheme.red)),
                const SizedBox(height: 4),
                Text(item.product.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Text(_currency(item.subtotal), style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: 'Remover',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => cart.remove(item.product),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Diminuir',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => cart.decrease(item.product),
                  ),
                  Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w900)),
                  IconButton(
                    tooltip: 'Aumentar',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => cart.add(item.product),
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

String _currency(double value) => 'R\$${value.toStringAsFixed(2).replaceAll('.', ',')}';
