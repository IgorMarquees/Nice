import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../controllers/address_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../models/order.dart';
import '../theme/nice_theme.dart';
import '../utils/feedback.dart';
import '../utils/formatters.dart';
import '../widgets/address_form.dart';
import '../widgets/responsive.dart';
import '../widgets/state_views.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fields = GlobalKey<AddressFieldsState>();
  PaymentMethod _payment = PaymentMethod.pix;

  /// Id do endereço salvo escolhido; null = digitar um novo.
  String? _selectedId;
  bool _choseManually = false;
  bool _saveNew = true;

  /// Seleciona o primeiro endereço salvo assim que a lista chega.
  String? _effectiveSelection(List<SavedAddress> saved) {
    if (_choseManually) return _selectedId;
    return saved.isEmpty ? null : saved.first.id;
  }

  Future<void> _confirm() async {
    final userId = context.read<AuthController>().user?.id;
    if (userId == null) return;

    final cart = context.read<CartController>();
    final orders = context.read<OrderController>();
    final addresses = context.read<AddressController>();
    final selectedId = _effectiveSelection(addresses.items);

    ShippingAddress address;
    if (selectedId != null) {
      address = addresses.items.firstWhere((a) => a.id == selectedId).address;
    } else {
      if (!_formKey.currentState!.validate()) return;
      final typed = _fields.currentState!.value;
      address = typed.address;
      if (_saveNew) await addresses.save(typed);
    }
    if (!mounted) return;

    final ok = await orders.placeOrder(
      userId: userId,
      items: cart.items,
      totals: OrderTotals.calculate(cart.total, _payment),
      paymentMethod: _payment,
      address: address,
    );

    if (!mounted) return;
    if (ok) {
      cart.clear();
      showMessage(context, 'Pedido realizado com sucesso!');
      context.go('/perfil');
    } else {
      showMessage(context, orders.error ?? 'Não foi possível finalizar a compra.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final orders = context.watch<OrderController>();
    final addresses = context.watch<AddressController>();
    final user = context.watch<AuthController>().user;
    final text = Theme.of(context).textTheme;

    if (cart.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'Seu carrinho está vazio',
        actionLabel: 'Ver catálogo',
        onAction: () => context.go('/catalogo'),
      );
    }

    final selectedId = _effectiveSelection(addresses.items);
    final totals = OrderTotals.calculate(cart.total, _payment);

    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('FINALIZAR COMPRA', style: text.headlineLarge),
          const SizedBox(height: 24),
          Text('ENDEREÇO DE ENTREGA', style: text.labelMedium),
          const SizedBox(height: 12),
          if (addresses.loading && addresses.items.isEmpty)
            const LinearProgressIndicator()
          else ...[
            for (final saved in addresses.items) ...[
              _SelectableCard(
                selected: selectedId == saved.id,
                onTap: () => setState(() {
                  _choseManually = true;
                  _selectedId = saved.id;
                }),
                child: AddressSummary(address: saved.address, title: saved.title),
              ),
              const SizedBox(height: 10),
            ],
            if (addresses.items.isNotEmpty)
              _SelectableCard(
                selected: selectedId == null,
                onTap: () => setState(() {
                  _choseManually = true;
                  _selectedId = null;
                }),
                child: Text('Usar outro endereço', style: text.titleSmall),
              ),
            if (selectedId == null) ...[
              const SizedBox(height: 16),
              AddressFields(key: _fields, initialRecipient: user?.name ?? '', showLabel: _saveNew),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _saveNew,
                onChanged: (v) => setState(() => _saveNew = v ?? false),
                title: const Text('Salvar este endereço no meu perfil'),
              ),
            ],
          ],
          const SizedBox(height: 28),
          Text('FORMA DE PAGAMENTO', style: text.labelMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final method in PaymentMethod.values)
                ChoiceChip(
                  label: Text(method == PaymentMethod.pix
                      ? '${method.label} (-${(AppConfig.pixDiscount * 100).round()}%)'
                      : method.label),
                  selected: _payment == method,
                  labelStyle: NiceTheme.chipLabel(selected: _payment == method),
                  onSelected: (_) => setState(() => _payment = method),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Pagando no Pix você ganha ${(AppConfig.pixDiscount * 100).round()}% de desconto no valor dos produtos.',
            style: text.bodySmall,
          ),
        ],
      ),
    );

    Widget line(String label, String value, {TextStyle? style}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(child: Text(label, style: text.bodyMedium)),
              const SizedBox(width: 12),
              Text(value, style: style ?? text.bodyMedium),
            ],
          ),
        );

    final summary = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NiceTheme.lightGray,
        borderRadius: BorderRadius.circular(NiceTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('SEU PEDIDO', style: text.titleLarge),
          const SizedBox(height: 16),
          for (final item in cart.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.title}${item.size.isEmpty ? '' : ' (${item.size})'}',
                      style: text.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(formatCurrency(item.subtotal), style: text.bodyMedium),
                ],
              ),
            ),
          const Divider(height: 28),
          line('Produtos', formatCurrency(totals.subtotal)),
          if (totals.discount > 0)
            line(
              'Desconto Pix (${(AppConfig.pixDiscount * 100).round()}%)',
              '- ${formatCurrency(totals.discount)}',
              style: text.bodyMedium?.copyWith(color: NiceTheme.success),
            ),
          line(
            'Frete',
            totals.freeShipping ? 'Grátis' : formatCurrency(totals.shipping),
            style: totals.freeShipping ? text.bodyMedium?.copyWith(color: NiceTheme.success) : null,
          ),
          if (!totals.freeShipping)
            Text(
              'Frete grátis a partir de ${formatCurrency(AppConfig.freeShippingThreshold)}.',
              style: text.bodySmall,
            ),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(child: Text('Total', style: text.titleLarge)),
              const SizedBox(width: 12),
              Text(formatCurrency(totals.total), style: text.headlineSmall?.copyWith(color: NiceTheme.red)),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: orders.submitting || addresses.saving ? null : _confirm,
            icon: orders.submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: NiceTheme.white))
                : const Icon(Icons.lock_outline),
            label: const Text('CONFIRMAR PEDIDO'),
          ),
        ],
      ),
    );

    return ContentWrapper(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.isDesktop ? 48 : 8),
        child: context.isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: form),
                  const SizedBox(width: 40),
                  SizedBox(width: 380, child: summary),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [form, const SizedBox(height: 28), summary, const SizedBox(height: 32)],
              ),
      ),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({required this.selected, required this.onTap, required this.child});

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(NiceTheme.radius),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(NiceTheme.radius),
          border: Border.all(color: selected ? NiceTheme.red : NiceTheme.softGray, width: selected ? 2 : 1.5),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? NiceTheme.red : NiceTheme.midGray,
            ),
            const SizedBox(width: 12),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
