import 'dart:math' as math;

import '../nucleo/processamento_texto.dart';
import 'modelo_categorias.dart';

class PrevisaoCategoria {
  const PrevisaoCategoria(this.categoria, this.confianca);

  final String categoria;

  /// Probabilidade da categoria vencedora entre 0 e 1.
  final double confianca;
}

/// Roda no app o modelo treinado em pln/treinar.py sem servidor e sem pacote extra.
class ClassificadorCategorias {
  const ClassificadorCategorias();

  /// Repete o TfidfVectorizer do scikit-learn: contagem vezes idf e norma L2.
  Map<int, double> vetorizar(String texto) {
    final contagem = <int, double>{};
    for (final termo in preprocessar(texto)) {
      final indice = vocabularioModelo[termo];
      if (indice != null) contagem[indice] = (contagem[indice] ?? 0) + 1;
    }
    contagem.updateAll((indice, valor) => valor * idfModelo[indice]);
    final norma = math.sqrt(contagem.values.fold(0.0, (soma, v) => soma + v * v));
    if (norma > 0) contagem.updateAll((_, valor) => valor / norma);
    return contagem;
  }

  /// Nada volta quando nenhuma palavra da consulta é conhecida pelo modelo.
  PrevisaoCategoria? prever(String texto) {
    final vetor = vetorizar(texto);
    if (vetor.isEmpty) return null;
    final pontos = [
      for (var c = 0; c < categoriasModelo.length; c++)
        vetor.entries.fold(logPrioriModelo[c], (soma, e) => soma + e.value * logProbTermosModelo[c][e.key]),
    ];
    final maior = pontos.reduce(math.max);
    final exponenciais = [for (final p in pontos) math.exp(p - maior)];
    final total = exponenciais.reduce((a, b) => a + b);
    final vencedora = pontos.indexOf(maior);
    return PrevisaoCategoria(categoriasModelo[vencedora], exponenciais[vencedora] / total);
  }
}
