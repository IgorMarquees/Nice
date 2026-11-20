import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../nucleo/configuracao.dart';
import '../../controladores/controlador_admin.dart';
import '../../controladores/controlador_autenticacao.dart';
import '../../controladores/controlador_carrinho.dart';
import '../../controladores/controlador_catalogo.dart';
import '../../dados/produto.dart';
import '../../nucleo/tema.dart';
import '../../nucleo/avisos.dart';
import '../../nucleo/formatadores.dart';
import '../../nucleo/navegacao.dart';
import '../componentes/trilha_navegacao.dart';
import '../componentes/imagem_rede.dart';
import '../componentes/etiqueta_preco.dart';
import '../componentes/responsivo.dart';
import '../componentes/estados_tela.dart';

class TelaProduto extends StatefulWidget {
  const TelaProduto({super.key, required this.idProduto});

  final String idProduto;

  @override
  State<TelaProduto> createState() => _TelaProdutoEstado();
}

class _TelaProdutoEstado extends State<TelaProduto> {
  Produto? _produto;
  /// Estoque lido só quando quem está logado é admin.
  int? _estoqueAdmin;
  bool _carregando = true;
  String? _tamanho;
  String? _cor;
  int _indiceFoto = 0;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final catalogo = context.read<ControladorCatalogo>();
    final ehAdmin = context.read<ControladorAutenticacao>().ehAdmin;
    final admin = context.read<ControladorAdmin>();
    if (!catalogo.carregado) await catalogo.carregar();
    final produto = await catalogo.encontrarPorId(widget.idProduto);
    final estoque = ehAdmin && produto != null && !produto.ehReserva
        ? (await admin.encontrarPorId(produto.id))?.estoque
        : null;
    if (!mounted) return;
    setState(() {
      _produto = produto;
      _estoqueAdmin = estoque;
      _carregando = false;
      if (produto != null && produto.tamanhos.length == 1) _tamanho = produto.tamanhos.first;
      if (produto != null && produto.cores.length == 1) _cor = produto.cores.first;
    });
  }

  /// Escolhe a cor e mostra as fotos dela.
  /// Tocar de novo na mesma cor desmarca e volta às fotos gerais.
  void _escolherCor(String cor) {
    setState(() {
      _cor = _cor == cor ? null : cor;
      _indiceFoto = 0;
    });
  }

  void _adicionarAoCarrinho(Produto produto) {
    if (!context.exigirLogin()) return;

    if (produto.tamanhos.isNotEmpty && _tamanho == null) {
      mostrarMensagem(context, 'Escolha um tamanho.');
      return;
    }
    if (produto.cores.isNotEmpty && _cor == null) {
      mostrarMensagem(context, 'Escolha uma cor.');
      return;
    }
    final variante = [?_tamanho, ?_cor].join(' / ');
    context.read<ControladorCarrinho>().adicionar(produto, tamanho: variante);
    avisarAdicionadoAoCarrinho(context, produto.titulo);
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Carregando();
    final produto = _produto;
    if (produto == null) {
      return EstadoVazio(
        icone: Icons.search_off,
        titulo: 'Produto não encontrado',
        textoAcao: 'Ver catálogo',
        aoAgir: () => context.go('/catalogo'),
      );
    }

    final galeria = _Galeria(
      fotos: produto.fotosDaCor(_cor),
      indice: _indiceFoto,
      percentualDesconto: produto.percentualDescontoAtivo,
      aoSelecionar: (i) => setState(() => _indiceFoto = i),
    );
    final aviso = _montarInfo(context, produto);
    final detalhes = produto.detalhesTecnicos.trim().isEmpty ? null : _DetalhesTecnicos(texto: produto.detalhesTecnicos);
    final trilha = TrilhaNavegacao(
      itens: [
        const ItemTrilha('Home', '/'),
        const ItemTrilha('Catálogo', '/catalogo'),
        if (produto.categoria.isNotEmpty)
          ItemTrilha(produto.categoria, caminhoCatalogo(categoria: produto.categoria, irParaProdutos: true)),
        ItemTrilha(produto.titulo),
      ],
    );

    return ConteudoCentralizado(
      conteudo: Padding(
        padding: EdgeInsets.symmetric(vertical: context.ehComputador ? 40 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            trilha,
            SizedBox(height: context.ehComputador ? 28 : 16),
            if (context.ehComputador)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: galeria),
                  const SizedBox(width: 56),
                  Expanded(flex: 5, child: aviso),
                ],
              )
            else ...[
              galeria,
              const SizedBox(height: 24),
              aviso,
            ],
            if (detalhes != null) ...[
              SizedBox(height: context.ehComputador ? 56 : 32),
              detalhes,
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _montarInfo(BuildContext context, Produto produto) {
    final texto = Theme.of(context).textTheme;
    final ehAdmin = context.watch<ControladorAutenticacao>().ehAdmin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(produto.titulo.toUpperCase(), style: texto.headlineLarge),
        const SizedBox(height: 14),
        EtiquetaPreco(produto: produto, grande: true),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            style: texto.bodyMedium,
            children: [
              TextSpan(text: formatarMoeda(produto.precoPix), style: texto.titleSmall?.copyWith(color: TemaNice.sucesso)),
              TextSpan(text: ' no Pix (${(Configuracao.descontoPix * 100).round()}% de desconto)'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _LinhaInfo(
          icone: Icons.local_shipping_outlined,
          texto: 'Frete grátis em compras a partir de ${formatarMoeda(Configuracao.freteGratisAPartirDe)}',
        ),
        const SizedBox(height: 20),
        Text(produto.descricao, style: texto.bodyLarge),
        if (produto.tamanhos.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text('TAMANHO', style: texto.labelMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tamanho in produto.tamanhos)
                ChoiceChip(
                  label: Text(tamanho),
                  selected: _tamanho == tamanho,
                  labelStyle: TemaNice.rotuloChip(selecionado: _tamanho == tamanho),
                  onSelected: (_) => setState(() => _tamanho = tamanho),
                ),
            ],
          ),
        ],
        if (produto.variantesCor.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('COR${_cor == null ? '' : ': ${_cor!.toUpperCase()}'}', style: texto.labelMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final variante in produto.variantesCor)
                ChoiceChip(
                  avatar: variante.fotos.isEmpty
                      ? null
                      : ClipOval(child: ImagemRede(url: variante.fotos.first, ajuste: BoxFit.cover)),
                  label: Text(variante.nome),
                  selected: _cor == variante.nome,
                  labelStyle: TemaNice.rotuloChip(selecionado: _cor == variante.nome),
                  onSelected: (_) => _escolherCor(variante.nome),
                ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        if (!produto.temEstoque)
          Text('Produto esgotado', style: texto.titleSmall?.copyWith(color: TemaNice.vermelho))
        else if (ehAdmin && _estoqueAdmin != null)
          _LinhaInfo(icone: Icons.inventory_2_outlined, texto: '$_estoqueAdmin em estoque (visível só para administradores)'),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: produto.temEstoque ? () => _adicionarAoCarrinho(produto) : null,
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(produto.temEstoque ? 'ADICIONAR AO CARRINHO' : 'ESGOTADO'),
          ),
        ),
      ],
    );
  }
}

class _LinhaInfo extends StatelessWidget {
  const _LinhaInfo({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 20, color: TemaNice.vermelho),
        const SizedBox(width: 8),
        Expanded(child: Text(texto, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}

class _DetalhesTecnicos extends StatelessWidget {
  const _DetalhesTecnicos({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final linhas = texto.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TemaNice.cinzaClaro,
        borderRadius: BorderRadius.circular(TemaNice.raio),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DETALHES TÉCNICOS', style: tema.labelMedium),
          const SizedBox(height: 14),
          for (final linha in linhas)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: tema.bodyMedium?.copyWith(color: TemaNice.vermelho)),
                  Expanded(child: Text(linha, style: tema.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Galeria extends StatelessWidget {
  const _Galeria({
    required this.fotos,
    required this.indice,
    required this.aoSelecionar,
    required this.percentualDesconto,
  });

  final List<String> fotos;
  final int indice;
  final int percentualDesconto;
  final ValueChanged<int> aoSelecionar;

  @override
  Widget build(BuildContext context) {
    final urls = fotos.isEmpty ? const [''] : fotos;
    final selecionado = indice.clamp(0, urls.length - 1);

    final main = AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(TemaNice.raio),
              child: ColoredBox(
                color: TemaNice.cinzaSuave,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: ImagemRede(key: ValueKey(urls[selecionado]), url: urls[selecionado]),
                ),
              ),
            ),
          ),
          if (percentualDesconto > 0)
            Positioned(right: 12, top: 12, child: SeloDesconto(percentual: percentualDesconto)),
        ],
      ),
    );
    if (urls.length < 2) return main;

    final miniaturas = [
      for (var i = 0; i < urls.length; i++)
        GestureDetector(
          onTap: () => aoSelecionar(i),
          child: Container(
            width: 72,
            height: 72,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TemaNice.raio),
              border: Border.all(color: i == selecionado ? TemaNice.vermelho : TemaNice.cinzaSuave, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(TemaNice.raio - 2),
              child: ImagemRede(url: urls[i], ajuste: BoxFit.cover),
            ),
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        main,
        const SizedBox(height: 12),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: miniaturas)),
      ],
    );
  }
}
