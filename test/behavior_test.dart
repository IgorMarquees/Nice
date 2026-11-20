import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:nice_store/src/controladores/controlador_carrinho.dart';
import 'package:nice_store/src/dados/usuario.dart';
import 'package:nice_store/src/dados/pedido.dart';
import 'package:nice_store/src/dados/produto.dart';
import 'package:nice_store/src/interface/telas/tela_login.dart';
import 'package:nice_store/src/interface/telas/pagina_rolavel.dart';
import 'package:nice_store/src/nucleo/tema.dart';
import 'package:nice_store/src/nucleo/avisos.dart';
import 'package:nice_store/src/nucleo/formatadores.dart';
import 'package:nice_store/src/interface/componentes/carrossel_banners.dart';
import 'package:nice_store/src/interface/componentes/imagem_banner.dart';
import 'package:nice_store/src/interface/componentes/cartao_produto.dart';

import 'test_harness.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('"Esqueceu a senha?" abre, envia e fecha sem exceção', (testador) async {
    final roteador = GoRouter(
      initialLocation: '/login',
      routes: [GoRoute(path: '/login', builder: (_, _) => const TelaLogin())],
    );
    await testador.pumpWidget(
      ProvedoresTeste(
        conteudo: MaterialApp.router(theme: TemaNice.claro(), routerConfig: roteador),
      ),
    );
    await testador.pump();

    await testador.tap(find.text('Esqueceu a senha?'));
    await testador.pumpAndSettle();
    await testador.enterText(find.byType(TextFormField).last, 'cliente@nice.com');
    await testador.tap(find.text('Enviar link'));
    await testador.pumpAndSettle();

    expect(find.text('Recuperar senha'), findsNothing);
    expect(testador.takeException(), isNull);
    await testador.pumpWidget(const SizedBox());
  });

  testWidgets('aviso de carrinho some sozinho e "VER CARRINHO" navega', (testador) async {
    final roteador = rotasTeste('/sobre', web: true);
    await testador.pumpWidget(
      ProvedoresTeste(
        conteudo: MaterialApp.router(theme: TemaNice.claro(), routerConfig: roteador),
      ),
    );
    await testador.pump();

    final context = testador.element(find.byType(Scaffold).first);
    avisarAdicionadoAoCarrinho(context, 'Kuro Tee');
    await testador.pumpAndSettle();
    expect(find.text('Kuro Tee adicionado ao carrinho'), findsOneWidget);

    await testador.pump(const Duration(seconds: 5));
    await testador.pumpAndSettle();
    expect(find.text('Kuro Tee adicionado ao carrinho'), findsNothing);

    avisarAdicionadoAoCarrinho(context, 'Kuro Tee');
    await testador.pumpAndSettle();
    await testador.tap(find.text('VER CARRINHO'));
    await testador.pumpAndSettle();
    expect(roteador.state.uri.path, '/carrinho');
    expect(find.text('Seu carrinho está vazio'), findsOneWidget);
    await testador.pumpWidget(const SizedBox());
  });

  testWidgets('produto: breadcrumbs, frete, Pix e estoque oculto para visitante', (testador) async {
    testador.view.physicalSize = const Size(1440, 1200);
    testador.view.devicePixelRatio = 1;
    final roteador = rotasTeste('/produto/fake-101', web: true);
    await testador.pumpWidget(
      ProvedoresTeste(
        conteudo: MaterialApp.router(theme: TemaNice.claro(), routerConfig: roteador),
      ),
    );
    await testador.pump(const Duration(milliseconds: 200));

    expect(find.text('HOME'), findsWidgets);
    expect(find.text('CATÁLOGO'), findsWidgets);
    expect(find.textContaining('Frete grátis em compras a partir de'), findsOneWidget);
    expect(find.textContaining('no Pix', findRichText: true), findsOneWidget);
    expect(find.textContaining('em estoque'), findsNothing);

    await testador.tap(find.text('CATÁLOGO').first);
    await testador.pumpAndSettle();
    expect(roteador.state.uri.path, '/catalogo');
    await testador.pumpWidget(const SizedBox());
    testador.view.reset();
  });

  const produtoColorido = Produto(
    id: 'p1',
    titulo: 'Oni Hoodie',
    descricao: 'Moletom',
    preco: 300,
    categoria: 'Moletons',
    percentualDesconto: 10,
    detalhesTecnicos: 'Composição: 100% algodão\nModelagem: oversized',
    tamanhos: ['M', '42'],
    variantesCor: [
      VarianteCor(nome: 'Preto', fotos: ['https://x/preto.jpg']),
      VarianteCor(nome: 'Branco', fotos: ['https://x/branco.jpg']),
    ],
    emDestaque: true,
    novidade: true,
  );

  testWidgets('produto: clicar na cor troca a foto grande; detalhes técnicos e desconto aparecem', (testador) async {
    testador.view.physicalSize = const Size(1440, 1400);
    testador.view.devicePixelRatio = 1;
    await testador.pumpWidget(
      ProvedoresTeste(
        produtos: const [produtoColorido],
        conteudo: MaterialApp.router(theme: TemaNice.claro(), routerConfig: rotasTeste('/produto/p1', web: true)),
      ),
    );
    await testador.pump(const Duration(milliseconds: 200));

    expect(find.text('DETALHES TÉCNICOS'), findsOneWidget);
    expect(find.text('-10%'), findsOneWidget);
    expect(find.text('R\$ 300,00'), findsOneWidget);
    expect(find.text('R\$ 270,00'), findsOneWidget);

    await testador.tap(find.text('Branco'));
    await testador.pumpAndSettle();
    expect(find.byKey(const ValueKey('https://x/branco.jpg')), findsOneWidget);
    await testador.tap(find.text('Branco'));
    await testador.pumpAndSettle();
    expect(find.text('COR'), findsOneWidget);
    expect(find.byKey(const ValueKey('https://x/preto.jpg')), findsOneWidget);
    await testador.tap(find.text('Preto'));
    await testador.pumpAndSettle();
    expect(find.byKey(const ValueKey('https://x/preto.jpg')), findsOneWidget);
    expect(testador.takeException(), isNull);
    await testador.pumpWidget(const SizedBox());
    testador.view.reset();
  });

  for (final largura in [360.0, 1440.0]) {
    testWidgets('checkout com carrinho cheio ($largura px): UF obrigatória, Pix e frete', (testador) async {
      testador.view.physicalSize = Size(largura, 1600);
      testador.view.devicePixelRatio = 1;
      final roteador = rotasTeste('/carrinho', web: true);
      await testador.pumpWidget(
        ProvedoresTeste(
          usuario: const Usuario(id: 'u1', email: 'c@nice.com', nome: 'Cliente'),
          produtos: const [produtoColorido],
          conteudo: MaterialApp.router(theme: TemaNice.claro(), routerConfig: roteador),
        ),
      );
      await testador.pump(const Duration(milliseconds: 100));
      final context = testador.element(find.byType(Scaffold).first);
      Provider.of<ControladorCarrinho>(context, listen: false).adicionar(produtoColorido, tamanho: 'M / Preto');
      roteador.go('/checkout');
      await testador.pumpAndSettle();

      expect(find.text('FINALIZAR COMPRA'), findsOneWidget);
      expect(find.text('UF'), findsOneWidget);
      expect(find.textContaining('Desconto Pix'), findsOneWidget);
      expect(find.text('Frete'), findsOneWidget);

      await testador.ensureVisible(find.text('CONFIRMAR PEDIDO'));
      await testador.tap(find.text('CONFIRMAR PEDIDO'));
      await testador.pumpAndSettle();
      expect(find.text('Selecione a UF'), findsOneWidget);
      expect(testador.takeException(), isNull);
      await testador.pumpWidget(const SizedBox());
      testador.view.reset();
    });
  }

  for (final tamanho in const [Size(1440, 700), Size(1920, 900), Size(1366, 650)]) {
    testWidgets('banner do topo cabe inteiro na tela em ${tamanho.width.toInt()}x${tamanho.height.toInt()}', (testador) async {
      testador.view.physicalSize = tamanho;
      testador.view.devicePixelRatio = 1;
      for (final rota in const ['/', '/novidades', '/catalogo', '/sobre']) {
        await testador.pumpWidget(
          ProvedoresTeste(
            conteudo: MaterialApp.router(theme: TemaNice.claro(), routerConfig: rotasTeste(rota, web: true)),
          ),
        );
        await testador.pump(const Duration(milliseconds: 100));
        final topo = rota == '/' ? find.byType(CarrosselBanners) : find.byType(ImagemBanner).first;
        final retangulo = testador.getRect(topo);
        expect(retangulo.bottom, lessThanOrEqualTo(tamanho.height + 0.5), reason: '$rota: banner termina em ${retangulo.bottom}');
        expect(testador.takeException(), isNull);
      }
      await testador.pumpWidget(const SizedBox());
      testador.view.reset();
    });
  }

  testWidgets('busca na navbar abre o Catálogo já rolado até os produtos', (testador) async {
    testador.view.physicalSize = const Size(1440, 900);
    testador.view.devicePixelRatio = 1;
    final roteador = rotasTeste('/sobre', web: true);
    await testador.pumpWidget(
      ProvedoresTeste(
        conteudo: MaterialApp.router(theme: TemaNice.claro(), routerConfig: roteador),
      ),
    );
    await testador.pump(const Duration(milliseconds: 100));

    await testador.enterText(find.byType(TextField).first, 'hoodie');
    await testador.testTextInput.receiveAction(TextInputAction.search);
    await testador.pumpAndSettle();

    expect(roteador.state.uri.path, '/catalogo');
    expect(roteador.state.uri.queryParameters['busca'], 'hoodie');
    final pagina = find.descendant(of: find.byType(PaginaRolavel), matching: find.byType(Scrollable)).first;
    final rolagem = testador.state<ScrollableState>(pagina);
    expect(rolagem.position.pixels, greaterThan(100), reason: 'deveria rolar até a área dos produtos');
    expect(testador.takeException(), isNull);
    await testador.pumpWidget(const SizedBox());
    testador.view.reset();
  });

  testWidgets('categoria da Home abre o Catálogo filtrado e rolado até os produtos', (testador) async {
    testador.view.physicalSize = const Size(1440, 900);
    testador.view.devicePixelRatio = 1;
    final roteador = rotasTeste('/', web: true);
    await testador.pumpWidget(
      ProvedoresTeste(
        conteudo: MaterialApp.router(theme: TemaNice.claro(), routerConfig: roteador),
      ),
    );
    await testador.pump(const Duration(milliseconds: 100));

    final categoria = find.text('MOLETONS');
    await testador.ensureVisible(categoria);
    await testador.pumpAndSettle();
    await testador.tap(categoria);
    await testador.pumpAndSettle();

    expect(roteador.state.uri.path, '/catalogo');
    expect(roteador.state.uri.queryParameters['categoria'], 'Moletons');
    final pagina = find.descendant(of: find.byType(PaginaRolavel), matching: find.byType(Scrollable)).first;
    final rolagem = testador.state<ScrollableState>(pagina);
    expect(rolagem.position.pixels, greaterThan(100), reason: 'deveria rolar até a área dos produtos');
    expect(testador.takeException(), isNull);
    await testador.pumpWidget(const SizedBox());
    testador.view.reset();
  });

  testWidgets('Home mostra só 3 destaques e não tem mais "Acabou de chegar"', (testador) async {
    testador.view.physicalSize = const Size(1440, 2400);
    testador.view.devicePixelRatio = 1;
    await testador.pumpWidget(
      ProvedoresTeste(
        conteudo: MaterialApp.router(theme: TemaNice.claro(), routerConfig: rotasTeste('/', web: true)),
      ),
    );
    await testador.pump(const Duration(milliseconds: 100));
    expect(find.text('ACABOU DE CHEGAR'), findsNothing);
    expect(find.byType(CartaoProduto), findsNWidgets(3));
    expect(testador.takeException(), isNull);
    await testador.pumpWidget(const SizedBox());
    testador.view.reset();
  });

  for (final largura in [400.0, 1440.0]) {
    testWidgets('perfil sem endereço mostra "Cadastrar endereço" e trocas ($largura px)', (testador) async {
      testador.view.physicalSize = Size(largura, 2400);
      testador.view.devicePixelRatio = 1;
      await testador.pumpWidget(
        ProvedoresTeste(
          usuario: const Usuario(id: 'u1', email: 'c@nice.com', nome: 'Cliente Teste'),
          conteudo: MaterialApp.router(theme: TemaNice.claro(), routerConfig: rotasTeste('/perfil', web: true)),
        ),
      );
      await testador.pumpAndSettle();
      expect(find.text('MEUS ENDEREÇOS'), findsOneWidget);
      expect(find.text('CADASTRAR ENDEREÇO'), findsOneWidget);
      expect(find.text('TROCAS E DEVOLUÇÕES'), findsOneWidget);
      expect(find.byTooltip('Instagram'), findsWidgets);
      expect(testador.takeException(), isNull);
      await testador.pumpWidget(const SizedBox());
      testador.view.reset();
    });
  }

  group('regras de preço', () {
    const produto = Produto(
      id: 'x',
      titulo: 'Teste',
      descricao: '',
      preco: 200,
      categoria: 'Camisetas',
      percentualDesconto: 20,
      variantesCor: [
        VarianteCor(nome: 'Preto', fotos: ['p1', 'p2']),
        VarianteCor(nome: 'Branco', fotos: ['b1']),
      ],
      fotos: ['geral'],
    );

    test('desconto, Pix e fotos por cor', () {
      expect(produto.precoFinal, 160);
      expect(produto.precoPix, 152);
      expect(produto.fotosDaCor('Branco'), ['b1']);
      expect(produto.fotosDaCor(null), ['geral', 'p1', 'p2', 'b1']);
      expect(produto.paraMapa()['colors'], ['Preto', 'Branco']);
      expect(produto.paraMapa().containsKey('stock'), isFalse);
    });

    test('desconto só vale dentro do período', () {
      final agora = DateTime.now();
      Produto comPeriodo(DateTime? inicio, DateTime? fim) => Produto(
            id: 'd',
            titulo: 'D',
            descricao: '',
            preco: 100,
            categoria: 'Camisetas',
            percentualDesconto: 30,
            inicioDesconto: inicio,
            fimDesconto: fim,
          );
      final agendado = comPeriodo(agora.add(const Duration(days: 1)), null);
      expect(agendado.situacaoDesconto, SituacaoDesconto.agendado);
      expect(agendado.precoFinal, 100);
      expect(agendado.percentualDescontoAtivo, 0);

      final ativo = comPeriodo(agora.subtract(const Duration(hours: 1)), agora.add(const Duration(hours: 1)));
      expect(ativo.situacaoDesconto, SituacaoDesconto.ativo);
      expect(ativo.precoFinal, 70);

      final encerrado = comPeriodo(null, agora.subtract(const Duration(minutes: 1)));
      expect(encerrado.situacaoDesconto, SituacaoDesconto.encerrado);
      expect(encerrado.precoFinal, 100);

      expect(comPeriodo(null, null).situacaoDesconto, SituacaoDesconto.ativo);
      expect(ativo.paraMapa()['discount_ends_at'], isA<String>());
    });

    test('frete grátis a partir de 400 e 5% no Pix', () {
      final pequeno = TotaisPedido.calcular(100, FormaPagamento.cartao);
      expect(pequeno.frete, greaterThan(0));
      final pix = TotaisPedido.calcular(400, FormaPagamento.pix);
      expect(pix.frete, 0);
      expect(pix.desconto, 20);
      expect(pix.total, 380);
    });

    test('máscara de CEP', () {
      final formatado = MascaraCep().formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '17500a000'),
      );
      expect(formatado.text, '17500-000');
    });
  });
}
