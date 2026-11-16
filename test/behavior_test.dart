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
import 'package:nice_store/src/screens/shell_page.dart';
import 'package:nice_store/src/theme/nice_theme.dart';
import 'package:nice_store/src/utils/feedback.dart';
import 'package:nice_store/src/utils/formatters.dart';
import 'package:nice_store/src/widgets/banner_carousel.dart';
import 'package:nice_store/src/widgets/banner_image.dart';
import 'package:nice_store/src/widgets/product_card.dart';

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
    expect(find.text('CATÁLOGO'), findsWidgets);
    expect(find.textContaining('Frete grátis em compras a partir de'), findsOneWidget);
    expect(find.textContaining('no Pix', findRichText: true), findsOneWidget);
    expect(find.textContaining('em estoque'), findsNothing);

    await tester.tap(find.text('CATÁLOGO').first);
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
    // Clicar de novo na cor selecionada desmarca e volta a mostrar todas as fotos.
    await tester.tap(find.text('Branco'));
    await tester.pumpAndSettle();
    expect(find.text('COR'), findsOneWidget);
    expect(find.byKey(const ValueKey('https://x/preto.jpg')), findsOneWidget);
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

  for (final size in const [Size(1440, 700), Size(1920, 900), Size(1366, 650)]) {
    testWidgets('banner do topo cabe inteiro na tela em ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      for (final route in const ['/', '/novidades', '/catalogo', '/sobre']) {
        await tester.pumpWidget(
          TestProviders(
            child: MaterialApp.router(theme: NiceTheme.light(), routerConfig: testRouter(route, web: true)),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        final top = route == '/' ? find.byType(BannerCarousel) : find.byType(BannerImage).first;
        final rect = tester.getRect(top);
        expect(rect.bottom, lessThanOrEqualTo(size.height + 0.5), reason: '$route: banner termina em ${rect.bottom}');
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
      tester.view.reset();
    });
  }

  testWidgets('busca na navbar abre o Catálogo já rolado até os produtos', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    final router = testRouter('/sobre', web: true);
    await tester.pumpWidget(
      TestProviders(
        child: MaterialApp.router(theme: NiceTheme.light(), routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField).first, 'hoodie');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/catalogo');
    expect(router.state.uri.queryParameters['busca'], 'hoodie');
    final page = find.descendant(of: find.byType(ShellPage), matching: find.byType(Scrollable)).first;
    final scrollable = tester.state<ScrollableState>(page);
    expect(scrollable.position.pixels, greaterThan(100), reason: 'deveria rolar até a área dos produtos');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    tester.view.reset();
  });

  testWidgets('Home mostra só 3 destaques e não tem mais "Acabou de chegar"', (tester) async {
    tester.view.physicalSize = const Size(1440, 2400);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      TestProviders(
        child: MaterialApp.router(theme: NiceTheme.light(), routerConfig: testRouter('/', web: true)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('ACABOU DE CHEGAR'), findsNothing);
    expect(find.byType(ProductCard), findsNWidgets(3));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    tester.view.reset();
  });

  for (final width in [400.0, 1440.0]) {
    testWidgets('perfil sem endereço mostra "Cadastrar endereço" e trocas ($width px)', (tester) async {
      tester.view.physicalSize = Size(width, 2400);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        TestProviders(
          user: const AppUser(id: 'u1', email: 'c@nice.com', name: 'Cliente Teste'),
          child: MaterialApp.router(theme: NiceTheme.light(), routerConfig: testRouter('/perfil', web: true)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('MEUS ENDEREÇOS'), findsOneWidget);
      expect(find.text('CADASTRAR ENDEREÇO'), findsOneWidget);
      expect(find.text('TROCAS E DEVOLUÇÕES'), findsOneWidget);
      expect(find.byTooltip('Instagram'), findsWidgets);
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

    test('desconto só vale dentro do período', () {
      final now = DateTime.now();
      Product withPeriod(DateTime? start, DateTime? end) => Product(
            id: 'd',
            title: 'D',
            description: '',
            price: 100,
            category: 'Camisetas',
            discountPercent: 30,
            discountStartsAt: start,
            discountEndsAt: end,
          );
      final scheduled = withPeriod(now.add(const Duration(days: 1)), null);
      expect(scheduled.discountStatus, DiscountStatus.scheduled);
      expect(scheduled.finalPrice, 100);
      expect(scheduled.activeDiscountPercent, 0);

      final active = withPeriod(now.subtract(const Duration(hours: 1)), now.add(const Duration(hours: 1)));
      expect(active.discountStatus, DiscountStatus.active);
      expect(active.finalPrice, 70);

      final expired = withPeriod(null, now.subtract(const Duration(minutes: 1)));
      expect(expired.discountStatus, DiscountStatus.expired);
      expect(expired.finalPrice, 100);

      expect(withPeriod(null, null).discountStatus, DiscountStatus.active);
      expect(active.toMap()['discount_ends_at'], isA<String>());
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
