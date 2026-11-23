import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../nucleo/imagens.dart';
import '../../nucleo/tema.dart';
import '../../controladores/controlador_catalogo.dart';
import '../componentes/imagem_banner.dart';
import '../componentes/secao_categorias.dart';
import '../componentes/painel_filtros.dart';
import '../componentes/grade_produtos.dart';
import '../componentes/responsivo.dart';
import '../componentes/estados_tela.dart';

class TelaCatalogo extends StatefulWidget {
  const TelaCatalogo({super.key, this.categoriaInicial, this.buscaInicial, this.rolarAteProdutos = false});

  final String? categoriaInicial;
  final String? buscaInicial;

  /// Quando veio de uma busca a página rola até os produtos.
  final bool rolarAteProdutos;

  @override
  State<TelaCatalogo> createState() => _TelaCatalogoEstado();
}

class _TelaCatalogoEstado extends State<TelaCatalogo> {
  late final TextEditingController _buscar;
  /// Marca o começo da área de produtos para a rolagem saber onde parar.
  final _chaveProdutos = GlobalKey();

  @override
  void initState() {
    super.initState();
    _buscar = TextEditingController(text: widget.buscaInicial ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final catalogo = context.read<ControladorCatalogo>();
      catalogo.aplicarFiltrosIniciais(categoria: widget.categoriaInicial, busca: widget.buscaInicial);
      catalogo.carregar();
      if (widget.rolarAteProdutos) _rolarAteProdutos();
    });
  }

  void _rolarAteProdutos() {
    final alvo = _chaveProdutos.currentContext;
    if (alvo == null) return;
    Scrollable.ensureVisible(alvo, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  void _abrirFiltros() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider<ControladorCatalogo>.value(
        value: context.read<ControladorCatalogo>(),
        child: const SafeArea(
          child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(24, 0, 24, 24), child: PainelFiltros()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogo = context.watch<ControladorCatalogo>();
    final texto = Theme.of(context).textTheme;
    final produtos = catalogo.filtrados;
    final computador = context.ehComputador;

    final campoBusca = TextField(
      controller: _buscar,
      onChanged: catalogo.definirBusca,
      decoration: InputDecoration(
        hintText: 'Buscar produtos...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _buscar.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _buscar.clear();
                  catalogo.definirBusca('');
                },
              ),
      ),
    );

    final previsao = catalogo.categoriaPrevista;
    final sugestao = previsao == null || previsao.categoria == catalogo.categoriaSelecionada
        ? null
        : _SugestaoCategoria(
            categoria: previsao.categoria,
            aoTocar: () {
              _buscar.clear();
              catalogo.definirBusca('');
              catalogo.definirCategoria(previsao.categoria);
            },
          );

    final resultados = catalogo.carregando && !catalogo.carregado
        ? const Carregando()
        : produtos.isEmpty
        ? EstadoVazio(
            icone: Icons.search_off,
            titulo: 'Nenhum produto encontrado',
            mensagem: 'Tente ajustar a busca ou os filtros.',
            textoAcao: 'Limpar filtros',
            aoAgir: () {
              _buscar.clear();
              catalogo.limparFiltros();
            },
          )
        : GradeProdutos(produtos: produtos, maxColunas: computador ? 3 : 4);

    if (!context.ehCelular) {
      final corpoCatalogo = computador
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 280, child: PainelFiltros()),
                const SizedBox(width: 48),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('CATÁLOGO', style: texto.displaySmall),
                      const SizedBox(height: 4),
                      Text('${produtos.length} produtos', style: texto.bodySmall),
                      const SizedBox(height: 20),
                      campoBusca,
                      if (sugestao != null) ...[const SizedBox(height: 12), sugestao],
                      const SizedBox(height: 28),
                      resultados,
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('CATÁLOGO', style: texto.headlineLarge),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: campoBusca),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(tooltip: 'Filtros', onPressed: _abrirFiltros, icon: const Icon(Icons.tune)),
                  ],
                ),
                if (sugestao != null) ...[const SizedBox(height: 12), sugestao],
                const SizedBox(height: 16),
                Text('${produtos.length} produtos', style: texto.bodySmall),
                const SizedBox(height: 16),
                resultados,
              ],
            );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ImagemBanner(
            arte: ImagensNice.catalogoTopo,
            caberNaTela: true,
            proporcao: 1755 / 896,
            rotulo: 'Explore os produtos. Ver todos os produtos',
            aoTocar: _rolarAteProdutos,
          ),
          Padding(
            key: _chaveProdutos,
            padding: EdgeInsets.only(top: computador ? 64 : 40),
            child: ConteudoCentralizado(conteudo: corpoCatalogo),
          ),
          SizedBox(height: computador ? 88 : 56),
        ],
      );
    }

    return Padding(
      key: _chaveProdutos,
      padding: EdgeInsets.symmetric(horizontal: context.margemPagina),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: campoBusca),
              const SizedBox(width: 10),
              IconButton.filledTonal(tooltip: 'Filtros', onPressed: _abrirFiltros, icon: const Icon(Icons.tune)),
            ],
          ),
          if (sugestao != null) ...[const SizedBox(height: 12), sugestao],
          const SizedBox(height: 16),
          const SecaoCategorias(),
          const SizedBox(height: 16),
          Text('${produtos.length} produtos', style: texto.bodySmall),
          const SizedBox(height: 16),
          resultados,
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Atalho para a categoria que o classificador de PLN previu a partir da busca.
class _SugestaoCategoria extends StatelessWidget {
  const _SugestaoCategoria({required this.categoria, required this.aoTocar});

  final String categoria;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        const Icon(Icons.auto_awesome, size: 16, color: TemaNice.vermelho),
        Text('Parece que você procura $categoria.', style: texto.bodySmall),
        TextButton(onPressed: aoTocar, child: Text('VER TUDO EM ${categoria.toUpperCase()}')),
      ],
    );
  }
}
