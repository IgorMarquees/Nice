import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/nice_theme.dart';
import '../utils/formatters.dart';

/// Desconto escolhido no diálogo (percentual + período opcional).
class DiscountInput {
  const DiscountInput({required this.percent, this.startsAt, this.endsAt});

  final int percent;

  /// null = começa imediatamente.
  final DateTime? startsAt;

  /// null = sem data de término.
  final DateTime? endsAt;
}

/// Valida um período: fim depois do início e ainda no futuro.
String? validateDiscountPeriod(DateTime? startsAt, DateTime? endsAt) {
  if (endsAt == null) return null;
  if (startsAt != null && !endsAt.isAfter(startsAt)) return 'O fim precisa ser depois do início.';
  if (!endsAt.isAfter(DateTime.now())) return 'O fim precisa ser no futuro.';
  return null;
}

/// "Ativo até 25/12/2026 às 18:00", "Agendado: começa em ...", etc.
String describeDiscount(Product product) {
  final start = product.discountStartsAt;
  final end = product.discountEndsAt;
  switch (product.discountStatus) {
    case DiscountStatus.none:
      return 'Sem desconto';
    case DiscountStatus.scheduled:
      return '-${product.discountPercent}% · começa em ${formatDateTime(start)}'
          '${end == null ? '' : ' · termina em ${formatDateTime(end)}'}';
    case DiscountStatus.active:
      return '-${product.discountPercent}% · ${end == null ? 'sem data de término' : 'até ${formatDateTime(end)}'}';
    case DiscountStatus.expired:
      return '-${product.discountPercent}% · encerrado em ${formatDateTime(end)}';
  }
}

/// Selo colorido com a situação do desconto (painel admin).
class DiscountStatusChip extends StatelessWidget {
  const DiscountStatusChip({super.key, required this.status});

  final DiscountStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      DiscountStatus.active => NiceTheme.success,
      DiscountStatus.scheduled => NiceTheme.red,
      DiscountStatus.expired => NiceTheme.midGray,
      DiscountStatus.none => NiceTheme.softGray,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: color,
      child: Text(
        status.label.toUpperCase(),
        style: NiceTheme.badge().copyWith(color: status == DiscountStatus.none ? NiceTheme.charcoal : NiceTheme.white),
      ),
    );
  }
}

/// Campo de data + hora (abre calendário e relógio). Pode ser limpo.
class DateTimeField extends StatelessWidget {
  const DateTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.emptyText,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  /// Texto quando vazio (ex.: "Imediatamente", "Sem data de término").
  final String emptyText;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final initial = value ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 3),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return;
    onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(NiceTheme.radius),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: value == null
              ? null
              : IconButton(tooltip: 'Limpar', icon: const Icon(Icons.close), onPressed: () => onChanged(null)),
        ),
        child: Text(
          value == null ? emptyText : formatDateTime(value),
          style: value == null ? text.bodyMedium?.copyWith(color: NiceTheme.textGray) : text.bodyMedium,
        ),
      ),
    );
  }
}

/// Diálogo "Aplicar desconto" (um produto ou vários de uma vez).
Future<DiscountInput?> showDiscountDialog(
  BuildContext context, {
  required String title,
  int initialPercent = 10,
  DateTime? startsAt,
  DateTime? endsAt,
}) {
  return showDialog<DiscountInput>(
    context: context,
    builder: (_) => _DiscountDialog(title: title, percent: initialPercent, startsAt: startsAt, endsAt: endsAt),
  );
}

class _DiscountDialog extends StatefulWidget {
  const _DiscountDialog({required this.title, required this.percent, this.startsAt, this.endsAt});

  final String title;
  final int percent;
  final DateTime? startsAt;
  final DateTime? endsAt;

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _percent = TextEditingController(text: '${widget.percent}');
  late DateTime? _startsAt = widget.startsAt;
  late DateTime? _endsAt = widget.endsAt;
  String? _periodError;

  @override
  void dispose() {
    _percent.dispose();
    super.dispose();
  }

  void _confirm() {
    final periodError = validateDiscountPeriod(_startsAt, _endsAt);
    setState(() => _periodError = periodError);
    if (!_formKey.currentState!.validate() || periodError != null) return;
    Navigator.pop(
      context,
      DiscountInput(percent: int.parse(_percent.text.trim()), startsAt: _startsAt, endsAt: _endsAt),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text(widget.title),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                TextFormField(
                  controller: _percent,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Desconto (%)', suffixText: '%'),
                  validator: validateDiscountPercent,
                ),
                const SizedBox(height: 12),
                DateTimeField(
                  label: 'Início',
                  value: _startsAt,
                  emptyText: 'Imediatamente',
                  onChanged: (v) => setState(() => _startsAt = v),
                ),
                const SizedBox(height: 12),
                DateTimeField(
                  label: 'Fim',
                  value: _endsAt,
                  emptyText: 'Sem data de término',
                  onChanged: (v) => setState(() => _endsAt = v),
                ),
                if (_periodError != null) ...[
                  const SizedBox(height: 8),
                  Text(_periodError!, style: text.bodySmall?.copyWith(color: NiceTheme.brightRed)),
                ],
                const SizedBox(height: 8),
                Text('Horários no fuso deste dispositivo.', style: text.bodySmall),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _confirm, child: const Text('Aplicar')),
      ],
    );
  }
}

String? validateDiscountPercent(String? value) {
  final percent = int.tryParse((value ?? '').trim());
  return percent == null || percent < 1 || percent > 90 ? 'Entre 1 e 90' : null;
}
