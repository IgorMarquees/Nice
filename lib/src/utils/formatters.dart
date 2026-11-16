import 'package:flutter/services.dart';

/// 1234.5 -> "R$ 1.234,50"
String formatCurrency(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'R\$ $intPart,${parts[1]}';
}

/// Mantém só dígitos e aplica a máscara 00000-000.
class CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);
    final text = digits.length > 5 ? '${digits.substring(0, 5)}-${digits.substring(5)}' : digits;
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// 25/12/2026 às 18:30
String formatDateTime(DateTime? date) {
  if (date == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${formatDate(date)} às ${two(date.hour)}:${two(date.minute)}';
}

String formatDate(DateTime? date) {
  if (date == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}';
}
