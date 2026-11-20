// Formatação de dinheiro datas e CEP.

import 'package:flutter/services.dart';

/// Transforma um número em reais no formato usado no Brasil.
String formatarMoeda(double valor) {
  final fixo = valor.toStringAsFixed(2);
  final partes = fixo.split('.');
  final parteInteira = partes[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'R\$ $parteInteira,${partes[1]}';
}

/// Deixa só números no CEP e coloca o traço no lugar certo.
class MascaraCep extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitos.length > 8) digitos = digitos.substring(0, 8);
    final texto = digitos.length > 5 ? '${digitos.substring(0, 5)}-${digitos.substring(5)}' : digitos;
    return TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: texto.length));
  }
}

/// Data com hora no formato dia mês ano às hora e minuto.
String formatarDataHora(DateTime? data) {
  if (data == null) return '';
  String doisDigitos(int n) => n.toString().padLeft(2, '0');
  return '${formatarData(data)} às ${doisDigitos(data.hour)}:${doisDigitos(data.minute)}';
}

/// Data no formato dia mês e ano.
String formatarData(DateTime? data) {
  if (data == null) return '';
  String doisDigitos(int n) => n.toString().padLeft(2, '0');
  return '${doisDigitos(data.day)}/${doisDigitos(data.month)}/${data.year}';
}
