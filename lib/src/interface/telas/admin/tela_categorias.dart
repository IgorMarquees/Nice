import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controladores/controlador_catalogo.dart';
import '../../../nucleo/avisos.dart';
import '../../../nucleo/tema.dart';
import '../../componentes/responsivo.dart';
import '../../componentes/estados_tela.dart';

class TelaCategorias extends StatefulWidget {
  const TelaCategorias({super.key});

  @override
  State<TelaCategorias> createState() => _TelaCategoriasEstado();
}

class _TelaCategoriasEstado extends State<TelaCategorias> {
  final _nome = TextEditingController();
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ControladorCatalogo>().carregar(forcar: true);
    });
  }

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Future<void> _criar() async {
    final catalogo = context.read<ControladorCatalogo>();
    setState(() => _salvando = true);
    final erro = await catalogo.criarCategoria(_nome.text);
    if (!mounted) return;
    setState(() => _salvando = false);
    if (erro == null) _nome.clear();
    mostrarMensagem(context, erro ?? 'Categoria criada.');
  }

  Future<void> _excluir(String categoria) async {
    final catalogo = context.read<ControladorCatalogo>();
    final qtd = catalogo.qtdProdutosDa(categoria);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir categoria'),
        content: Text(
          qtd == 0
              ? 'Deseja excluir "$categoria"?'
              : 'Deseja excluir "$categoria"? Os $qtd produto(s) dela vão para "${ControladorCatalogo.semCategoria}".',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    setState(() => _salvando = true);
    final erro = await catalogo.excluirCategoria(categoria);
    if (!mounted) return;
    setState(() => _salvando = false);
    mostrarMensagem(context, erro ?? 'Categoria excluída.');
  }

  @override
  Widget build(BuildContext context) {
    final catalogo = context.watch<ControladorCatalogo>();
    final texto = Theme.of(context).textTheme;
    final categorias = catalogo.categoriasCadastro;

    return ConteudoCentralizado(
      larguraMaxima: 900,
      conteudo: Padding(
        padding: EdgeInsets.symmetric(vertical: context.ehComputador ? 48 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('PAINEL ADMIN', style: texto.labelMedium),
            const SizedBox(height: 4),
            Text('CATEGORIAS', style: texto.headlineLarge),
            const SizedBox(height: 6),
            Text(
              'Ao excluir uma categoria os produtos dela vão para "${ControladorCatalogo.semCategoria}".',
              style: texto.bodySmall,
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _nome,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _salvando ? null : _criar(),
                    decoration: const InputDecoration(hintText: 'Nome da nova categoria'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _salvando ? null : _criar,
                    icon: const Icon(Icons.add),
                    label: Text(context.ehCelular ? 'CRIAR' : 'CRIAR CATEGORIA'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (catalogo.carregando && !catalogo.carregado)
              const Carregando()
            else
              for (final categoria in categorias) ...[
                _ItemCategoria(
                  nome: categoria,
                  qtdProdutos: catalogo.qtdProdutosDa(categoria),
                  protegida: categoria == ControladorCatalogo.semCategoria,
                  aoExcluir: _salvando ? null : () => _excluir(categoria),
                ),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ItemCategoria extends StatelessWidget {
  const _ItemCategoria({
    required this.nome,
    required this.qtdProdutos,
    required this.protegida,
    required this.aoExcluir,
  });

  final String nome;
  final int qtdProdutos;
  final bool protegida;
  final VoidCallback? aoExcluir;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TemaNice.raio),
        border: Border.all(color: TemaNice.cinzaSuave, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.sell_outlined, color: TemaNice.vermelho),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome, style: texto.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  protegida ? '$qtdProdutos produto(s) · não pode ser excluída' : '$qtdProdutos produto(s)',
                  style: texto.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: protegida ? 'Categoria protegida' : 'Excluir categoria',
            icon: const Icon(Icons.delete_outline),
            onPressed: protegida ? null : aoExcluir,
          ),
        ],
      ),
    );
  }
}
