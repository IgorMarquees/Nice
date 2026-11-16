import 'package:flutter/material.dart';

import '../models/order.dart';
import '../theme/nice_theme.dart';
import '../utils/formatters.dart';
import 'address_form.dart';

/// Card de pedido (usado no perfil e no painel admin de usuários).
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});

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
          if (!order.address.isEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.local_shipping_outlined, size: 18, color: NiceTheme.textGray),
                const SizedBox(width: 8),
                Expanded(child: AddressSummary(address: order.address, title: 'Entregue em')),
              ],
            ),
          ],
          const Divider(height: 24),
          if (order.discount > 0 || order.shipping > 0) ...[
            if (order.discount > 0)
              Text('Desconto Pix: - ${formatCurrency(order.discount)}', style: text.bodySmall),
            Text(
              'Frete: ${order.shipping > 0 ? formatCurrency(order.shipping) : 'Grátis'}',
              style: text.bodySmall,
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              Expanded(child: Text(order.paymentMethod.label, style: text.bodySmall)),
              const SizedBox(width: 12),
              Text(formatCurrency(order.total), style: text.titleSmall),
            ],
          ),
        ],
      ),
    );
  }
}
