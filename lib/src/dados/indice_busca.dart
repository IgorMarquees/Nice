import 'dart:math' as math;

import '../nucleo/processamento_texto.dart';
import 'produto.dart';

/// Busca por relevância com TF-IDF e similaridade do cosseno sobre os produtos carregados.
class IndiceBusca {
  IndiceBusca(List<Produto> produtos) {
    final contagens = <String, Map<String, double>>{};
    final frequenciaDocumentos = <String, int>{};
    for (final p in produtos) {
      final contagem = <String, double>{};
      for (final termo in _termosDoProduto(p)) {
        contagem[termo] = (contagem[termo] ?? 0) + 1;
      }
      contagens[p.id] = contagem;
      for (final termo in contagem.keys) {
        frequenciaDocumentos[termo] = (frequenciaDocumentos[termo] ?? 0) + 1;
      }
      _textoCorrido[p.id] = normalizarTexto('${p.titulo} ${p.descricao} ${p.categoria}');
    }
    final n = produtos.length;
    frequenciaDocumentos.forEach((termo, df) => _idf[termo] = math.log((1 + n) / (1 + df)) + 1);
    contagens.forEach((id, contagem) {
      contagem.updateAll((termo, tf) => tf * _idf[termo]!);
      _vetores[id] = _normalizado(contagem);
    });
  }

  final _vetores = <String, Map<String, double>>{};
  final _idf = <String, double>{};
  final _textoCorrido = <String, String>{};

  /// O título pesa mais que a categoria e a categoria mais que a descrição.
  static List<String> _termosDoProduto(Produto p) => [
    for (var i = 0; i < 3; i++) ...preprocessar(p.titulo),
    for (var i = 0; i < 2; i++) ...preprocessar(p.categoria),
    ...preprocessar(p.cores.join(' ')),
    ...preprocessar(p.descricao),
    ...preprocessar(p.detalhesTecnicos),
  ];

  static Map<String, double> _normalizado(Map<String, double> vetor) {
    final norma = math.sqrt(vetor.values.fold(0.0, (soma, v) => soma + v * v));
    return norma == 0 ? vetor : vetor.map((termo, v) => MapEntry(termo, v / norma));
  }

  /// Termo desconhecido vale pelos parecidos: começo de palavra enquanto digita ou um erro de digitação.
  Map<String, double> _expandir(String termo) {
    if (_idf.containsKey(termo)) return {termo: 1};
    final parecidos = <String, double>{};
    final limite = termo.length >= 7 ? 2 : 1;
    for (final conhecido in _idf.keys) {
      if (termo.length >= 3 && conhecido.startsWith(termo)) {
        parecidos[conhecido] = 0.8;
      } else if (termo.length >= 4 && distanciaEdicao(termo, conhecido, limite: limite) <= limite) {
        parecidos[conhecido] = 0.7;
      }
    }
    return parecidos;
  }

  /// Nota de 0 a 1 de cada produto que combina com a consulta.
  Map<String, double> pontuar(String consulta) {
    final vetorConsulta = <String, double>{};
    for (final termo in preprocessar(consulta)) {
      _expandir(termo).forEach((conhecido, peso) {
        vetorConsulta[conhecido] = (vetorConsulta[conhecido] ?? 0) + peso * _idf[conhecido]!;
      });
    }
    final consultaNormalizada = _normalizado(vetorConsulta);
    final textoConsulta = normalizarTexto(consulta);
    final pontos = <String, double>{};
    _vetores.forEach((id, vetor) {
      var nota = 0.0;
      consultaNormalizada.forEach((termo, peso) => nota += peso * (vetor[termo] ?? 0));
      // Mantém o comportamento antigo de achar o texto exato em qualquer parte do produto
      if (textoConsulta.isNotEmpty && _textoCorrido[id]!.contains(textoConsulta)) nota += 0.5;
      if (nota > 0) pontos[id] = nota;
    });
    return pontos;
  }
}
