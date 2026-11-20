// Varredura de responsividade.
// Abre todas as telas em mais de 20 larguras e falha se algo estourar.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nice_store/src/dados/usuario.dart';
import 'package:nice_store/src/nucleo/tema.dart';

import 'test_harness.dart';

/// Administrador falso usado para testar as telas do painel.
const _administrador = Usuario(id: 'admin-1', email: 'admin@nice.com', nome: 'Admin NICE', papel: PapelUsuario.admin);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  const larguras = <double>[
    320, 360, 412, 560, 639, 640, 700, 780, 860, 899, 900, 950,
    979, 980, 1000, 1023, 1024, 1100, 1180, 1239, 1240, 1280, 1440, 1920,
  ];
  const rotas = [
    '/', '/novidades', '/catalogo', '/sobre', '/carrinho', '/produto/fake-101', '/admin',
    '/admin/produtos', '/admin/descontos', '/admin/usuarios', '/admin/produto/novo', '/checkout', '/perfil', '/login', '/cadastro',
  ];

  for (final usuario in [null, _administrador]) {
    for (final web in [true, false]) {
      for (final rota in rotas) {
        final quem = usuario == null ? 'visitante' : 'admin';
        testWidgets('${web ? 'web' : 'mobile'} ($quem) $rota em várias larguras', (testador) async {
          for (final largura in larguras) {
            testador.view.physicalSize = Size(largura, 900);
            testador.view.devicePixelRatio = 1;
            await testador.pumpWidget(
              ProvedoresTeste(
                usuario: usuario,
                conteudo: MaterialApp.router(
                  theme: TemaNice.claro(),
                  routerConfig: rotasTeste(rota, web: web),
                ),
              ),
            );
            await testador.pump(const Duration(milliseconds: 100));
            await testador.pump(const Duration(milliseconds: 100));
            final erro = testador.takeException();
            expect(erro, isNull, reason: 'largura $largura: $erro');
            await testador.pumpWidget(const SizedBox());
          }
          testador.view.reset();
        });
      }
    }
  }

  for (final web in [true, false]) {
    testWidgets('${web ? 'web' : 'mobile'}: redimensionar e trocar de rota sem exceções', (testador) async {
      testador.view.devicePixelRatio = 1;
      testador.view.physicalSize = const Size(1440, 900);
      final roteador = rotasTeste('/', web: web);
      await testador.pumpWidget(
        ProvedoresTeste(
          usuario: _administrador,
          conteudo: MaterialApp.router(theme: TemaNice.claro(), routerConfig: roteador),
        ),
      );
      await testador.pump(const Duration(milliseconds: 100));
      const caminhos = ['/novidades', '/catalogo', '/sobre', '/produto/fake-102', '/carrinho', '/admin', '/'];
      var i = 0;
      for (var largura = 1440.0; largura >= 320; largura -= 37) {
        testador.view.physicalSize = Size(largura, 900);
        await testador.pump();
        roteador.go(caminhos[i++ % caminhos.length]);
        await testador.pump();
        await testador.pump(const Duration(milliseconds: 150));
        await testador.pump(const Duration(milliseconds: 400));
        expect(testador.takeException(), isNull, reason: 'largura $largura');
      }
      await testador.pumpWidget(const SizedBox());
      testador.view.reset();
    });
  }
}
