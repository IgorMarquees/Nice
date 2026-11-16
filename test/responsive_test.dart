import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nice_store/src/models/app_user.dart';
import 'package:nice_store/src/theme/nice_theme.dart';

import 'test_harness.dart';

const _admin = AppUser(id: 'admin-1', email: 'admin@nice.com', name: 'Admin NICE', role: UserRole.admin);

/// Varre várias larguras (incluindo as próximas dos breakpoints), nas
/// molduras Web e mobile, como visitante e como admin, e falha se houver
/// overflow ou qualquer exceção.
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  const widths = <double>[
    320, 360, 412, 560, 639, 640, 700, 780, 860, 899, 900, 950, //
    979, 980, 1000, 1023, 1024, 1100, 1180, 1239, 1240, 1280, 1440, 1920,
  ];
  const routes = [
    '/', '/novidades', '/catalogo', '/sobre', '/carrinho', '/produto/fake-101', '/admin', //
    '/admin/produtos', '/admin/descontos', '/admin/usuarios', '/admin/produto/novo', '/checkout', '/perfil', '/login', '/cadastro',
  ];

  for (final user in [null, _admin]) {
    for (final web in [true, false]) {
      for (final route in routes) {
        final who = user == null ? 'visitante' : 'admin';
        testWidgets('${web ? 'web' : 'mobile'} ($who) $route em várias larguras', (tester) async {
          for (final width in widths) {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            await tester.pumpWidget(
              TestProviders(
                user: user,
                child: MaterialApp.router(
                  theme: NiceTheme.light(),
                  routerConfig: testRouter(route, web: web),
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 100));
            await tester.pump(const Duration(milliseconds: 100));
            final error = tester.takeException();
            expect(error, isNull, reason: 'largura $width: $error');
            await tester.pumpWidget(const SizedBox());
          }
          tester.view.reset();
        });
      }
    }
  }

  for (final web in [true, false]) {
    testWidgets('${web ? 'web' : 'mobile'}: redimensionar e trocar de rota sem exceções', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 900);
      final router = testRouter('/', web: web);
      await tester.pumpWidget(
        TestProviders(
          user: _admin,
          child: MaterialApp.router(theme: NiceTheme.light(), routerConfig: router),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      const paths = ['/novidades', '/catalogo', '/sobre', '/produto/fake-102', '/carrinho', '/admin', '/'];
      var i = 0;
      for (var width = 1440.0; width >= 320; width -= 37) {
        tester.view.physicalSize = Size(width, 900);
        await tester.pump();
        router.go(paths[i++ % paths.length]);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull, reason: 'largura $width');
      }
      await tester.pumpWidget(const SizedBox());
      tester.view.reset();
    });
  }
}
