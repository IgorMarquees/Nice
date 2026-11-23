// Busca inteligente do catálogo: pré-processamento, classificador de categoria e ranking TF-IDF.
// Os casos de teste do classificador são exportados por pln/treinar.py junto com o modelo.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nice_store/src/dados/classificador_categorias.dart';
import 'package:nice_store/src/dados/indice_busca.dart';
import 'package:nice_store/src/dados/repositorio_vitrine_reserva.dart';
import 'package:nice_store/src/nucleo/processamento_texto.dart';
import 'package:nice_store/src/nucleo/tema.dart';

import 'test_harness.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  final exportado = jsonDecode(File('test/dados_pln/casos_teste.json').readAsStringSync()) as Map<String, dynamic>;

  group('pré-processamento', () {
    test('tira acentos e pontuação e passa para minúsculas', () {
      expect(normalizarTexto('Calça JAPONESA, estilo Tóquio!'), 'calca japonesa estilo toquio');
    });

    test('remove palavras sem valor para a busca', () {
      expect(preprocessar('quero uma camiseta para o verão'), ['camiseta', 'verao']);
    });

    test('plural vira singular', () {
      expect(preprocessar('moletons calças bonés anéis cores'), ['moletom', 'calca', 'bone', 'anel', 'cor']);
      expect(preprocessar('tênis jeans'), ['tenis', 'jeans']);
    });

    test('grafias diferentes da mesma peça viram uma palavra só', () {
      expect(preprocessar('moleton hoodie'), ['moletom', 'moletom']);
      expect(preprocessar('T-shirt camisa tee'), ['t', 'camiseta', 'camiseta', 'camiseta']);
    });

    test('distância de edição aceita um erro de digitação', () {
      expect(distanciaEdicao('camizeta', 'camiseta'), 1);
      expect(distanciaEdicao('moletm', 'moletom'), 1);
      expect(distanciaEdicao('bone', 'calca'), greaterThan(2));
    });

    test('Dart e Python geram os mesmos termos', () {
      for (final caso in (exportado['preprocessamento'] as List).cast<Map<String, dynamic>>()) {
        expect(preprocessar(caso['texto'] as String), (caso['termos'] as List).cast<String>(), reason: caso['texto'] as String);
      }
    });
  });

  group('classificador de categoria', () {
    const classificador = ClassificadorCategorias();
    final casos = (exportado['casos'] as List).cast<Map<String, dynamic>>();

    test('o modelo no app prevê igual ao modelo treinado em Python', () {
      for (final caso in casos) {
        final previsao = classificador.prever(caso['texto'] as String);
        // Sem nenhuma palavra conhecida o Python chuta pela proporção das classes e o app prefere não sugerir
        if (previsao == null) {
          expect(classificador.vetorizar(caso['texto'] as String), isEmpty);
          continue;
        }
        expect(previsao.categoria, caso['previsto'], reason: caso['texto'] as String);
        expect(previsao.confianca, closeTo(caso['confianca'] as double, 1e-4), reason: caso['texto'] as String);
      }
    });

    test('acurácia no conjunto de teste fica acima de 90%', () {
      final acertos = casos.where((c) => classificador.prever(c['texto'] as String)?.categoria == c['real']).length;
      expect(acertos / casos.length, greaterThanOrEqualTo(0.9));
    });

    test('entende pedidos sem o nome da peça', () {
      expect(classificador.prever('algo pra esquentar no frio')?.categoria, 'Moletons');
      expect(classificador.prever('algo pra cabeça')?.categoria, 'Acessórios');
      expect(classificador.prever('boné preto')?.categoria, 'Acessórios');
      expect(classificador.prever('jogger cinza')?.categoria, 'Calças');
    });

    test('sem palavra conhecida não arrisca uma categoria', () {
      expect(classificador.prever('xyzabc'), isNull);
      expect(classificador.prever(''), isNull);
    });
  });

  group('ranking da busca', () {
    final indice = IndiceBusca(RepositorioVitrineReserva().produtosReserva);
    List<String> encontrados(String consulta) {
      final pontos = indice.pontuar(consulta);
      return (pontos.keys.toList()..sort((a, b) => pontos[b]!.compareTo(pontos[a]!)));
    }

    test('acha a peça pelo nome da categoria e por sinônimos', () {
      expect(encontrados('moleton'), unorderedEquals(['fake-103', 'fake-104']));
      expect(encontrados('camisa'), unorderedEquals(['fake-101', 'fake-102']));
    });

    test('tolera erro de digitação e palavra pela metade', () {
      expect(encontrados('moletm'), unorderedEquals(['fake-103', 'fake-104']));
      expect(encontrados('camizeta'), unorderedEquals(['fake-101', 'fake-102']));
      expect(encontrados('cyber'), ['fake-103']);
    });

    test('o produto mais parecido vem primeiro', () {
      expect(encontrados('hoodie noturno neon').first, 'fake-103');
    });

    test('consulta sem relação não traz nada', () {
      expect(encontrados('geladeira'), isEmpty);
    });
  });

  testWidgets('catálogo usa a busca inteligente e sugere a categoria prevista', (testador) async {
    testador.view.physicalSize = const Size(1440, 900);
    testador.view.devicePixelRatio = 1;
    await testador.pumpWidget(
      ProvedoresTeste(
        conteudo: MaterialApp.router(theme: TemaNice.claro(), routerConfig: rotasTeste('/catalogo?busca=moleton', web: true)),
      ),
    );
    await testador.pumpAndSettle();

    expect(find.text('Neon Drift Hoodie'), findsOneWidget);
    expect(find.text('Yoru Pulse Hoodie'), findsOneWidget);
    expect(find.text('Kuro Essential Tee'), findsNothing);
    expect(find.text('2 produtos'), findsOneWidget);

    final atalho = find.text('VER TUDO EM MOLETONS');
    expect(atalho, findsOneWidget);
    await testador.ensureVisible(atalho);
    await testador.tap(atalho);
    await testador.pumpAndSettle();
    expect(find.text('VER TUDO EM MOLETONS'), findsNothing);
    expect(find.text('2 produtos'), findsOneWidget);
    expect(testador.takeException(), isNull);
    await testador.pumpWidget(const SizedBox());
    testador.view.reset();
  });
}
