import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/address_controller.dart';
import '../models/order.dart';
import '../theme/nice_theme.dart';
import '../utils/formatters.dart';
import 'responsive.dart';

/// Campos de endereço com preenchimento automático pelo CEP (ViaCEP)
/// e UF obrigatória escolhida da lista de estados.
///
/// Use dentro de um [Form]; leia o resultado com
/// `GlobalKey<AddressFieldsState>().currentState!.value`.
class AddressFields extends StatefulWidget {
  const AddressFields({super.key, this.initial, this.initialRecipient = '', this.showLabel = false});

  final SavedAddress? initial;
  final String initialRecipient;

  /// Mostra o campo "Apelido" (Casa, Trabalho...) usado nos endereços salvos.
  final bool showLabel;

  @override
  State<AddressFields> createState() => AddressFieldsState();
}

class AddressFieldsState extends State<AddressFields> {
  late final _label = TextEditingController(text: widget.initial?.label ?? '');
  late final _recipient = TextEditingController(text: widget.initial?.address.recipient ?? widget.initialRecipient);
  late final _zip = TextEditingController(text: widget.initial?.address.zip ?? '');
  late final _street = TextEditingController(text: widget.initial?.address.street ?? '');
  late final _number = TextEditingController(text: widget.initial?.address.number ?? '');
  late final _complement = TextEditingController(text: widget.initial?.address.complement ?? '');
  late final _neighborhood = TextEditingController(text: widget.initial?.address.neighborhood ?? '');
  late final _city = TextEditingController(text: widget.initial?.address.city ?? '');
  final _numberFocus = FocusNode();
  late String? _state = brazilianStates.contains(widget.initial?.address.state) ? widget.initial!.address.state : null;

  bool _searching = false;
  String? _cepMessage;
  String _lastLookup = '';

  List<TextEditingController> get _controllers =>
      [_label, _recipient, _zip, _street, _number, _complement, _neighborhood, _city];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _numberFocus.dispose();
    super.dispose();
  }

  SavedAddress get value => SavedAddress(
        id: widget.initial?.id ?? '',
        label: _label.text.trim(),
        address: ShippingAddress(
          recipient: _recipient.text.trim(),
          zip: _zip.text.trim(),
          street: _street.text.trim(),
          number: _number.text.trim(),
          complement: _complement.text.trim(),
          neighborhood: _neighborhood.text.trim(),
          city: _city.text.trim(),
          state: _state ?? '',
        ),
      );

  Future<void> _onZipChanged(String value) async {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8 || digits == _lastLookup) return;
    _lastLookup = digits;
    setState(() {
      _searching = true;
      _cepMessage = null;
    });
    final result = await context.read<AddressController>().lookupCep(digits);
    if (!mounted) return;
    setState(() {
      _searching = false;
      if (result == null) {
        _cepMessage = 'CEP não encontrado. Preencha o endereço manualmente.';
        return;
      }
      if (result.street.isNotEmpty) _street.text = result.street;
      if (result.neighborhood.isNotEmpty) _neighborhood.text = result.neighborhood;
      if (result.city.isNotEmpty) _city.text = result.city;
      if (brazilianStates.contains(result.state)) _state = result.state;
    });
    _numberFocus.requestFocus();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Obrigatório' : null;

  Widget _row(List<Widget> fields, {List<int>? flex}) {
    if (context.isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < fields.length; i++) ...[if (i > 0) const SizedBox(height: 12), fields[i]],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(flex: flex?[i] ?? 1, child: fields[i]),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLabel) ...[
          TextFormField(
            controller: _label,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Apelido (ex.: Casa, Trabalho)'),
          ),
          const SizedBox(height: 12),
        ],
        TextFormField(
          controller: _recipient,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome do destinatário'),
          validator: _required,
        ),
        const SizedBox(height: 12),
        _row([
          TextFormField(
            controller: _zip,
            keyboardType: TextInputType.number,
            inputFormatters: [CepInputFormatter()],
            onChanged: _onZipChanged,
            decoration: InputDecoration(
              labelText: 'CEP',
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : const Icon(Icons.search, color: NiceTheme.red),
            ),
            validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length == 8 ? null : 'CEP inválido',
          ),
          DropdownButtonFormField<String>(
            key: ValueKey(_state),
            initialValue: _state,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'UF'),
            items: [for (final uf in brazilianStates) DropdownMenuItem(value: uf, child: Text(uf))],
            onChanged: (v) => setState(() => _state = v),
            validator: (v) => v == null ? 'Selecione a UF' : null,
          ),
        ]),
        if (_cepMessage != null) ...[
          const SizedBox(height: 6),
          Text(_cepMessage!, style: text.bodySmall?.copyWith(color: NiceTheme.red)),
        ],
        const SizedBox(height: 12),
        _row(
          [
            TextFormField(
              controller: _street,
              decoration: const InputDecoration(labelText: 'Rua / Avenida'),
              validator: _required,
            ),
            TextFormField(
              controller: _number,
              focusNode: _numberFocus,
              decoration: const InputDecoration(labelText: 'Número'),
              validator: _required,
            ),
          ],
          flex: const [3, 1],
        ),
        const SizedBox(height: 12),
        _row([
          TextFormField(
            controller: _complement,
            decoration: const InputDecoration(labelText: 'Complemento (opcional)'),
          ),
          TextFormField(
            controller: _neighborhood,
            decoration: const InputDecoration(labelText: 'Bairro'),
            validator: _required,
          ),
        ]),
        const SizedBox(height: 12),
        TextFormField(
          controller: _city,
          decoration: const InputDecoration(labelText: 'Cidade'),
          validator: _required,
        ),
      ],
    );
  }
}

/// Diálogo para cadastrar/editar um endereço salvo no perfil.
Future<SavedAddress?> showAddressDialog(BuildContext context, {SavedAddress? initial, String recipient = ''}) {
  return showDialog<SavedAddress>(
    context: context,
    builder: (_) => _AddressDialog(initial: initial, recipient: recipient),
  );
}

class _AddressDialog extends StatefulWidget {
  const _AddressDialog({this.initial, required this.recipient});

  final SavedAddress? initial;
  final String recipient;

  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fields = GlobalKey<AddressFieldsState>();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = context.read<AddressController>();
    final saved = await controller.save(_fields.currentState!.value);
    if (!mounted) return;
    if (saved != null) Navigator.pop(context, saved);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AddressController>();
    return AlertDialog(
      title: Text(widget.initial == null ? 'Novo endereço' : 'Editar endereço'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                AddressFields(
                  key: _fields,
                  initial: widget.initial,
                  initialRecipient: widget.recipient,
                  showLabel: true,
                ),
                if (controller.error != null) ...[
                  const SizedBox(height: 12),
                  Text(controller.error!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: NiceTheme.red)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: controller.saving ? null : _save,
          child: controller.saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: NiceTheme.white))
              : const Text('Salvar'),
        ),
      ],
    );
  }
}

/// Lista só-leitura de um endereço (perfil, pedidos, painel admin).
class AddressSummary extends StatelessWidget {
  const AddressSummary({super.key, required this.address, this.title});

  final ShippingAddress address;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) Text(title!, style: text.titleSmall),
        if (address.recipient.isNotEmpty) Text(address.recipient, style: text.bodyMedium),
        Text(address.oneLine, style: text.bodySmall),
      ],
    );
  }
}
