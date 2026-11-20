import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../nucleo/imagens.dart';
import '../../controladores/controlador_catalogo.dart';
import '../../dados/produto.dart';
import '../../nucleo/tema.dart';
import '../../nucleo/navegacao.dart';
import '../componentes/imagem_banner.dart';
import '../componentes/imagem_rede.dart';
import '../componentes/carrossel_produtos.dart';
import '../componentes/responsivo.dart';
import '../componentes/cabecalho_secao.dart';
import '../componentes/estados_tela.dart';

class TelaNovidades extends StatelessWidget {
  const TelaNovidades({super.key});

  @override
  Widget build(BuildContext context) {
    final catalogo = context.watch<ControladorCatalogo>();
    final computador = context.ehComputador;
    final listaNovidades = catalogo.novidades;
    final destaqueDaVez = catalogo.destaques.isNotEmpty ? catalogo.destaques.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ImagemBanner(
          arte: ImagensNice.novidadesTopo,
          caberNaTela: true,
          proporcao: 2876 / 1472,
          proporcaoApp: 1.2,
          rotulo: 'Just dropped. Ver todos os lançamentos',
          aoTocar: () => context.go(caminhoCatalogo(irParaProdutos: true)),
        ),
        SizedBox(height: computador ? 72 : 32),
        ConteudoCentralizado(
          conteudo: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CabecalhoSecao(sobretitulo: 'ÚLTIMOS LANÇAMENTOS', titulo: 'Peças que acabaram\nde chegar'),
              SizedBox(height: computador ? 40 : 24),
              if (catalogo.carregando && listaNovidades.isEmpty)
                const Carregando()
              else if (listaNovidades.isEmpty)
                const EstadoVazio(icone: Icons.new_releases_outlined, titulo: 'Em breve novos lançamentos')
              else
                CarrosselProdutos(produtos: listaNovidades),
            ],
          ),
        ),
        if (destaqueDaVez != null) ...[SizedBox(height: computador ? 72 : 36), _EmDestaque(produto: destaqueDaVez)],
        SizedBox(height: computador ? 88 : 48),
        ImagemBanner(
          arte: ImagensNice.catalogoFinal,
          proporcao: 2880 / 960,
          proporcaoApp: 1.6,
          rotulo: 'Todas as peças. Um só estilo. Ver todos os produtos',
          aoTocar: () => context.go(caminhoCatalogo(irParaProdutos: true)),
        ),
      ],
    );
  }
}

class _EmDestaque extends StatelessWidget {
  const _EmDestaque({required this.produto});

  final Produto produto;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final computador = context.ehComputador;
    final celular = context.ehCelular;
    void abrir() => context.push('/produto/${produto.id}');

    final aviso = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('EM DESTAQUE', style: texto.labelMedium),
        const SizedBox(height: 10),
        Text(produto.titulo.toUpperCase(), style: TemaNice.tituloDestaque(grande: !celular)),
        const SizedBox(height: 16),
        Text(produto.descricao, style: texto.bodyLarge),
        const SizedBox(height: 28),
        InkWell(
          onTap: abrir,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('VER DETALHES', style: TemaNice.linkEspacado()),
                const SizedBox(width: 18),
                const Icon(Icons.arrow_outward, size: 20, color: TemaNice.vermelhoVivo),
              ],
            ),
          ),
        ),
      ],
    );

    const editorial = AspectRatio(
      aspectRatio: 826 / 679,
      child: Image(image: AssetImage(ImagensNice.novidadesDestaque), fit: BoxFit.cover),
    );

    final fotoProduto = AspectRatio(
      aspectRatio: 0.82,
      child: Stack(
        children: [
          const Positioned(right: 0, top: 24, bottom: 24, width: 96, child: ColoredBox(color: TemaNice.vermelhoVivo)),
          Positioned.fill(
            right: 28,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: abrir,
                child: ImagemRede(url: produto.urlFoto),
              ),
            ),
          ),
        ],
      ),
    );

    final kanji = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 1, height: 56, color: TemaNice.grafite),
        const SizedBox(height: 14),
        Text('東', style: TemaNice.kanji()),
        Text('京', style: TemaNice.kanji()),
        const SizedBox(height: 14),
        Container(width: 1, height: 56, color: TemaNice.grafite),
      ],
    );

    final Widget montagem;
    if (computador) {
      montagem = Row(
        children: [
          const Expanded(flex: 9, child: editorial),
          const SizedBox(width: 40),
          Expanded(flex: 7, child: aviso),
          const SizedBox(width: 24),
          Expanded(flex: 5, child: fotoProduto),
          SizedBox(width: 88, child: Center(child: kanji)),
        ],
      );
    } else if (!celular) {
      montagem = Row(
        children: [
          const Expanded(child: editorial),
          Expanded(
            child: Padding(padding: const EdgeInsets.all(32), child: aviso),
          ),
        ],
      );
    } else {
      montagem = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          editorial,
          Padding(padding: const EdgeInsets.all(24), child: aviso),
        ],
      );
    }

    return ConteudoCentralizado(
      conteudo: ColoredBox(color: TemaNice.cinzaSecao, child: montagem),
    );
  }
}
