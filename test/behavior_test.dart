import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:nice_store/src/controllers/cart_controller.dart';
import 'package:nice_store/src/models/app_user.dart';
import 'package:nice_store/src/models/order.dart';
import 'package:nice_store/src/models/product.dart';
import 'package:nice_store/src/screens/login_screen.dart';
import 'package:nice_store/src/theme/nice_theme.dart';
import 'package:nice_store/src/utils/feedback.dart';
import 'package:nice_store/src/utils/formatters.dart';

import 'test_harness.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('"Esqueceu a senha?" abre, envia e fecha sem exceção', (tester) async {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [GoRoute(path: '/login', builder: (_, _) => const LoginScreen())],
    );
    await tester.pumpWidget(
      TestProviders(
        child: MaterialApp.router(theme: NiceTheme.light(), routerConfig: router),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Esqueceu a senha?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'cliente@nice.com');
    await tester.tap(find.text('Enviar link'));
    await tester.pumpAndSettle();

    expect(find.text('Recuperar senha'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('aviso de carrinho some sozinho e "VER CARRINHO" navega', (tester) async {
    final router = testRouter('/sobre', web: true);
    await tester.pumpWidget(
      TestProviders(
        child: MaterialApp.router(theme: NiceTheme.light(), routerConfig: router),
      ),
    );
    await tester.pump();

    final context = tester.element(find.byType(Scaffold).first);
    showAddedToCart(context, 'Kuro Tee');
    await tester.pumpAndSettle();
    expect(find.text('Kuro Tee adicionado ao carrinho'), findsOneWidget);

    // Some sozinho (antes ficava fixo por ter ação).
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Kuro Tee adicionado ao carrinho'), findsNothing);

    // O botão leva ao carrinho.
    showAddedToCart(context, 'Kuro Tee');
    await tester.pumpAndSettle();
    await tester.tap(find.text('VER CARRINHO'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/carrinho');
    expect(find.text('Seu carrinho está vazio'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('produto: breadcrumbs, frete, Pix e estoque oculto para visitante', (tester) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    final router = testRouter('/produto/fake-101', web: true);
    await tester.pumpWidget(
      TestProviders(
        child: MaterialApp.router(theme: NiceTheme.light(), routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('HOME'), findsWidgets);
    expect(find.text('CATEGORIAS'), findsWidgets);
    expect(find.textContaining('Frete grátis em compras a partir de'), findsOneWidget);
    expect(find.textContaining('no Pix', findRichText: true), findsOneWidget);
    expect(find.textContaining('em estoque'), findsNothing);

    await tester.tap(find.text('CATEGORIAS').first);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/catalogo');
    await tester.pumpWidget(const SizedBox());
    tester.view.reset();
  });

  const colorful = Product(
    id: 'p1',
    title: 'Oni Hoodie',
    description: 'Moletom',
    price: 300,
    category: 'Moletons',
    discountPercent: 10,
    technicalDetails: 'Composição: 100% algodão\nModelagem: oversized',
    sizes: ['M', '42'],
    colorVariants: [
      ColorVariant(name: 'Preto', images: ['https://x/preto.jpg']),
      ColorVariant(name: 'Branco', images: ['https://x/branco.jpg']),
    ],
    isFeatured: true,
    isNew: true,
  );

  testWidgets('produto: clicar na cor troca a foto grande; detalhes técnicos e desconto aparecem', (tester) async {
    tester.view.physicalSize = const Size(1440, 1400);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      TestProviders(
        products: const [colorful],
        child: MaterialApp.router(theme: NiceTheme.light(), routerConfig: testRouter('/produto/p1', web: true)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('DETALHES TÉCNICOS'), findsOneWidget);
    expect(find.text('-10%'), findsOneWidget);
    expect(find.text('R\$ 300,00'), findsOneWidget); // preço cheio riscado
    expect(find.text('R\$ 270,00'), findsOneWidget); // preço com desconto

    await tester.tap(find.text('Branco'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('https://x/branco.jpg')), findsOneWidget);
    await tester.tap(find.text('Preto'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('https://x/preto.jpg')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    tester.view.reset();
  });

  for (final width in [360.0, 1440.0]) {
    testWidgets('checkout com carrinho cheio ($width px): UF obrigatória, Pix e frete', (tester) async {
      tester.view.physicalSize = Size(width, 1600);
      tester.view.devicePixelRatio = 1;
      final router = testRouter('/carrinho', web: true);
      await tester.pumpWidget(
        TestProviders(
          user: const AppUser(id: 'u1', email: 'c@nice.com', name: 'Cliente'),
          products: const [colorful],
          child: MaterialApp.router(theme: NiceTheme.light(), routerConfig: router),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final context = tester.element(find.byType(Scaffold).first);
      Provider.of<CartController>(context, listen: false).add(colorful, size: 'M / Preto');
      router.go('/checkout');
      await tester.pumpAndSettle();

      expect(find.text('FINALIZAR COMPRA'), findsOneWidget);
      expect(find.text('UF'), findsOneWidget);
      expect(find.textContaining('Desconto Pix'), findsOneWidget);
      expect(find.text('Frete'), findsOneWidget);

      // Sem UF o pedido não segue.
      await tester.ensureVisible(find.text('CONFIRMAR PEDIDO'));
      await tester.tap(find.text('CONFIRMAR PEDIDO'));
      await tester.pumpAndSettle();
      expect(find.text('Selecione a UF'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      tester.view.reset();
    });
  }

  group('regras de preço', () {
    const product = Product(
      id: 'x',
      title: 'Teste',
      description: '',
      price: 200,
      category: 'Camisetas',
      discountPercent: 20,
      colorVariants: [
        ColorVariant(name: 'Preto', images: ['p1', 'p2']),
        ColorVariant(name: 'Branco', images: ['b1']),
      ],
      images: ['geral'],
    );

    test('desconto, Pix e fotos por cor', () {
      expect(product.finalPrice, 160);
      expect(product.pixPrice, 152);
      expect(product.imagesFor('Branco'), ['b1']);
      expect(product.imagesFor(null), ['geral', 'p1', 'p2', 'b1']);
      expect(product.toMap()['colors'], ['Preto', 'Branco']);
      expect(product.toMap().containsKey('stock'), isFalse);
    });

    test('frete grátis a partir de 400 e 5% no Pix', () {
      final small = OrderTotals.calculate(100, PaymentMethod.card);
      expect(small.shipping, greaterThan(0));
      final pix = OrderTotals.calculate(400, PaymentMethod.pix);
      expect(pix.shipping, 0);
      expect(pix.discount, 20);
      expect(pix.total, 380);
    });

    test('máscara de CEP', () {
      final formatted = CepInputFormatter().formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '17500a000'),
      );
      expect(formatted.text, '17500-000');
    });
  });
}
