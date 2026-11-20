// Página inicial.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../nucleo/imagens.dart';
import '../../controladores/controlador_autenticacao.dart';
import '../../controladores/controlador_catalogo.dart';
import '../../dados/produto.dart';
import '../../nucleo/tema.dart';
import '../../nucleo/navegacao.dart';
import '../componentes/carrossel_banners.dart';
import '../componentes/imagem_banner.dart';
import '../componentes/secao_categorias.dart';
import '../componentes/cartao_produto.dart';
import '../componentes/grade_produtos.dart';
import '../componentes/responsivo.dart';
import '../componentes/cabecalho_secao.dart';
import '../componentes/estados_tela.dart';

/// Banners do carrossel do topo.
const _slides = [
  SlideBanner(
    imagem: ImagensNice.inicioBanner1,
    proporcao: 2880 / 1500,
    rota: '/catalogo',
    rotulo: 'Beyond the streets. Explore a coleção',
  ),
  SlideBanner(
    imagem: ImagensNice.inicioBanner2,
    proporcao: 2880 / 1500,
    rota: '/catalogo',
    rotulo: 'Cultura em movimento. Explore a coleção',
  ),
];

/// Carrossel destaques e categorias.
class TelaInicio extends StatelessWidget {
  const TelaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    final catalogo = context.watch<ControladorCatalogo>();
    final computador = context.ehComputador;
    final celular = context.ehCelular;
    final destaques = catalogo.destaques.take(3).toList();
    final espaco = SizedBox(height: computador ? 88 : 40);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (celular) const _SaudacaoCelular(),
        const CarrosselBanners(slides: _slides, proporcaoApp: 1.2),
        if (celular) ...[
          const SizedBox(height: 20),
          const ConteudoCentralizado(conteudo: SecaoCategorias()),
        ],
        if (kIsWeb) ...[
          SizedBox(height: computador ? 56 : 28),
          ImagemBanner(
            arte: ImagensNice.inicioEssencia,
            proporcao: 2880 / 800,
            rotulo: 'A essência da NICE. Conheça a NICE',
            aoTocar: () => context.go('/sobre'),
          ),
        ],
        espaco,
        ConteudoCentralizado(
          conteudo: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CabecalhoSecao(
                sobretitulo: 'Destaques',
                titulo: 'Escolhas do momento',
                textoAcao: 'Ver mais',
                aoAgir: () => context.go(caminhoCatalogo(irParaProdutos: true)),
              ),
              SizedBox(height: computador ? 40 : 24),
              if (catalogo.carregando && destaques.isEmpty)
                const Carregando()
              else if (celular)
                _FaixaDestaques(produtos: destaques)
              else
                LinhaProdutos(produtos: destaques, colunas: 3, espaco: 24),
            ],
          ),
        ),
        espaco,
        if (!celular) const _FaixaCategorias() else const SizedBox(height: 16),
      ],
    );
  }
}

/// Faixa clara de categorias que escurece até o rodapé no site.
class _FaixaCategorias extends StatelessWidget {
  const _FaixaCategorias();

  @override
  Widget build(BuildContext context) {
    final computador = context.ehComputador;
    const cabecalho = CabecalhoSecao(sobretitulo: 'Categorias', titulo: 'Explore\npor estilo');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColoredBox(
          color: TemaNice.cinzaSecao,
          child: Padding(
            padding: EdgeInsets.only(top: computador ? 72 : 48, bottom: kIsWeb ? 0 : 48),
            child: ConteudoCentralizado(
              conteudo: computador
                  ? const Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: 280, child: cabecalho),
                        SizedBox(width: 32),
                        Expanded(child: SecaoCategorias()),
                      ],
                    )
                  : const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [cabecalho, SizedBox(height: 24), SecaoCategorias()],
                    ),
            ),
          ),
        ),
        if (kIsWeb)
          const SizedBox(
            height: 160,
            child: DecoratedBox(decoration: BoxDecoration(gradient: TemaNice.degradeRodape)),
          ),
      ],
    );
  }
}

/// No celular as três peças rolam para o lado.
class _FaixaDestaques extends StatelessWidget {
  const _FaixaDestaques({required this.produtos});

  final List<Produto> produtos;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < produtos.length; i++) ...[
            if (i > 0) const SizedBox(width: 14),
            SizedBox(width: 170, child: CartaoProduto(produto: produtos[i])),
          ],
        ],
      ),
    );
  }
}

/// Saudação e campo de busca no celular.
class _SaudacaoCelular extends StatelessWidget {
  const _SaudacaoCelular();

  @override
  Widget build(BuildContext context) {
    final autenticacao = context.watch<ControladorAutenticacao>();
    final texto = Theme.of(context).textTheme;
    final nome = autenticacao.usuario?.nome.split(' ').first;

    return Padding(
      padding: EdgeInsets.fromLTRB(context.margemPagina, 4, context.margemPagina, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(nome == null ? 'Bem-vindo à NICE' : 'Bem-vindo, $nome', style: texto.headlineSmall),
          const SizedBox(height: 14),
          TextField(
            textInputAction: TextInputAction.search,
            onSubmitted: (valor) {
              context.buscarNoCatalogo(valor);
            },
            decoration: const InputDecoration(
              hintText: 'Encontre seu drip...',
              prefixIcon: Icon(Icons.search, color: TemaNice.vermelho),
            ),
          ),
        ],
      ),
    );
  }
}
