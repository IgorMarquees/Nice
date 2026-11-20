// Moldura do app no celular.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controladores/controlador_carrinho.dart';
import '../../nucleo/tema.dart';
import '../componentes/logo_nice.dart';

/// Logo no topo e barra vermelha embaixo com a busca no centro.
/// Igual no Android e no iOS.
class MolduraCelular extends StatelessWidget {
  const MolduraCelular({super.key, required this.local, required this.conteudo});

  final String local;
  final Widget conteudo;

  /// Qual item da barra fica aceso para a página atual.
  int get _indice {
    if (local == '/') return 0;
    if (local.startsWith('/novidades')) return 1;
    if (local.startsWith('/catalogo')) return 2;
    if (local.startsWith('/carrinho') || local.startsWith('/checkout')) return 3;
    if (local.startsWith('/perfil') || local.startsWith('/admin')) return 4;
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final qtdCarrinho = context.watch<ControladorCarrinho>().qtdItens;
    final indice = _indice;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BarraTopo(podeVoltar: context.canPop()),
            Expanded(child: conteudo),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Buscar',
        onPressed: () => context.go('/catalogo'),
        backgroundColor: TemaNice.vermelho,
        foregroundColor: TemaNice.branco,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.search, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        height: 72,
        child: Row(
          children: [
            _ItemBarra(
              icone: Icons.home_outlined,
              iconeSelecionado: Icons.home,
              rotulo: 'Home',
              selecionado: indice == 0,
              aoTocar: () => context.go('/'),
            ),
            _ItemBarra(
              icone: Icons.new_releases_outlined,
              iconeSelecionado: Icons.new_releases,
              rotulo: 'Novidades',
              selecionado: indice == 1,
              aoTocar: () => context.go('/novidades'),
            ),
            const SizedBox(width: 72),
            _ItemBarra(
              icone: Icons.shopping_bag_outlined,
              iconeSelecionado: Icons.shopping_bag,
              rotulo: 'Carrinho',
              selecionado: indice == 3,
              contador: qtdCarrinho,
              aoTocar: () => context.go('/carrinho'),
            ),
            _ItemBarra(
              icone: Icons.person_outline,
              iconeSelecionado: Icons.person,
              rotulo: 'Perfil',
              selecionado: indice == 4,
              aoTocar: () => context.go('/perfil'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra do topo com o logo e o botão de voltar.
class _BarraTopo extends StatelessWidget {
  const _BarraTopo({required this.podeVoltar});

  final bool podeVoltar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const LogoNice(pequena: true),
          if (podeVoltar)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Voltar',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Um item da barra de baixo.
class _ItemBarra extends StatelessWidget {
  const _ItemBarra({
    required this.icone,
    required this.iconeSelecionado,
    required this.rotulo,
    required this.selecionado,
    required this.aoTocar,
    this.contador = 0,
  });

  final IconData icone;
  final IconData iconeSelecionado;
  final String rotulo;
  final bool selecionado;
  final VoidCallback aoTocar;
  final int contador;

  @override
  Widget build(BuildContext context) {
    final cor = selecionado ? TemaNice.branco : TemaNice.cinzaSuave;
    final estilo = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cor,
          fontWeight: selecionado ? FontWeight.w800 : FontWeight.w500,
        );

    return Expanded(
      child: InkWell(
        onTap: aoTocar,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: contador > 0,
              label: Text('$contador'),
              backgroundColor: TemaNice.branco,
              textColor: TemaNice.vermelho,
              child: Icon(selecionado ? iconeSelecionado : icone, color: cor, size: 26),
            ),
            const SizedBox(height: 4),
            Text(rotulo, style: estilo),
          ],
        ),
      ),
    );
  }
}
