import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../models/order.dart';
import '../theme/nice_theme.dart';
import '../utils/formatters.dart';
import '../widgets/responsive.dart';
import '../widgets/state_views.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _recipient;
  final _zip = TextEditingController();
  final _street = TextEditingController();
  final _number = TextEditingController();
  final _complement = TextEditingController();
  final _neighborhood = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  PaymentMethod _payment = PaymentMethod.pix;

  @override
  void initState() {
    super.initState();
    _recipient = TextEditingController(text: context.read<AuthController>().user?.name ?? '');
  }

  @override
  void dispose() {
    for (final c in [_recipient, _zip, _street, _number, _complement, _neighborhood, _city, _state]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Obrigatório' : null;

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthController>().user?.id;
    if (userId == null) return;

    final cart = context.read<CartController>();
    final orders = context.read<OrderController>();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await orders.placeOrder(
      userId: userId,
      items: cart.items,
      total: cart.total,
      paymentMethod: _payment,
      address: ShippingAddress(
        recipient: _recipient.text.trim(),
        zip: _zip.text.trim(),
        street: _street.text.trim(),
        number: _number.text.trim(),
        complement: _complement.text.trim(),
        neighborhood: _neighborhood.text.trim(),
        city: _city.text.trim(),
        state: _state.text.trim().toUpperCase(),
      ),
    );

    if (!mounted) return;
    if (ok) {
      cart.clear();
      messenger.showSnackBar(const SnackBar(content: Text('Pedido realizado com sucesso!')));
      context.go('/perfil');
    } else {
      messenger.showSnackBar(SnackBar(content: Text(orders.error ?? 'Não foi possível finalizar a compra.')));
    }
  }

  Widget _row(List<Widget> fields) {
    if (!context.isCompact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: fields[i]),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < fields.length; i++) ...[if (i > 0) const SizedBox(height: 12), fields[i]],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final orders = context.watch<OrderController>();
    final text = Theme.of(context).textTheme;

    if (cart.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'Seu carrinho está vazio',
        actionLabel: 'Ver catálogo',
        onAction: () => context.go('/catalogo'),
      );
    }

    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('FINALIZAR COMPRA', style: text.headlineLarge),
          const SizedBox(height: 24),
          Text('ENDEREÇO DE ENTREGA', style: text.labelMedium),
          const SizedBox(height: 12),
          TextFormField(
            controller: _recipient,
            decoration: const InputDecoration(hintText: 'Nome do destinatário'),
            validator: _required,
          ),
          const SizedBox(height: 12),
          _row([
            TextFormField(controller: _zip, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'CEP'), validator: _required),
            TextFormField(controller: _state, textCapitalization: TextCapitalization.characters, maxLength: 2, decoration: const InputDecoration(hintText: 'UF', counterText: ''), validator: _required),
          ]),
          const SizedBox(height: 12),
          _row([
            TextFormField(controller: _street, decoration: const InputDecoration(hintText: 'Rua / Avenida'), validator: _required),
            TextFormField(controller: _number, decoration: const InputDecoration(hintText: 'Número'), validator: _required),
          ]),
          const SizedBox(height: 12),
          _row([
            TextFormField(controller: _complement, decoration: const InputDecoration(hintText: 'Complemento (opcional)')),
            TextFormField(controller: _neighborhood, decoration: const InputDecoration(hintText: 'Bairro'), validator: _required),
          ]),
          const SizedBox(height: 12),
          TextFormField(controller: _city, decoration: const InputDecoration(hintText: 'Cidade'), validator: _required),
          const SizedBox(height: 28),
          Text('FORMA DE PAGAMENTO', style: text.labelMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final method in PaymentMethod.values)
                ChoiceChip(
                  label: Text(method.label),
                  selected: _payment == method,
                  labelStyle: NiceTheme.chipLabel(selected: _payment == method),
                  onSelected: (_) => setState(() => _payment = method),
                ),
            ],
          ),
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
          Row(
            children: [
              Text('Total', style: text.titleLarge),
              const Spacer(),
              Text(formatCurrency(cart.total), style: text.headlineSmall?.copyWith(color: NiceTheme.red)),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: orders.submitting ? null : _confirm,
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
