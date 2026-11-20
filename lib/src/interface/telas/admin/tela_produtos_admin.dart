// Lista de produtos do administrador.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../controladores/controlador_admin.dart';
import '../../../controladores/controlador_catalogo.dart';
import '../../../dados/produto.dart';
import '../../../nucleo/tema.dart';
import '../../../nucleo/formatadores.dart';
import '../../componentes/imagem_rede.dart';
import '../../componentes/responsivo.dart';
import '../../componentes/estados_tela.dart';

/// Busca chaves de Destaque e Novidade editar e excluir.
class TelaProdutosAdmin extends StatefulWidget {
  const TelaProdutosAdmin({super.key});

  @override
  State<TelaProdutosAdmin> createState() => _TelaProdutosAdminEstado();
}

class _TelaProdutosAdminEstado extends State<TelaProdutosAdmin> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ControladorAdmin>().carregar();
    });
  }

  /// Liga ou desliga Destaque ou Novidade e atualiza a loja.
  Future<void> _marcar(Produto produto, {bool? emDestaque, bool? novidade}) async {
    final admin = context.read<ControladorAdmin>();
    final catalogo = context.read<ControladorCatalogo>();
    final mensageiro = ScaffoldMessenger.of(context);
    final deuCerto = await admin.definirMarcacoes(produto, emDestaque: emDestaque, novidade: novidade);
    if (deuCerto) {
      catalogo.carregar(forcar: true);
    } else {
      mensageiro.showSnackBar(SnackBar(content: Text(admin.erro ?? 'Erro ao atualizar.')));
    }
  }

  /// Pede confirmação e exclui o produto.
  Future<void> _excluir(Produto produto) async {
    final admin = context.read<ControladorAdmin>();
    final catalogo = context.read<ControladorCatalogo>();
    final mensageiro = ScaffoldMessenger.of(context);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir produto'),
        content: Text('Deseja excluir "${produto.titulo}"? Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmado != true) return;
    final deuCerto = await admin.excluir(produto);
    if (deuCerto) {
      catalogo.carregar(forcar: true);
      mensageiro.showSnackBar(const SnackBar(content: Text('Produto excluído.')));
    } else {
      mensageiro.showSnackBar(SnackBar(content: Text(admin.erro ?? 'Erro ao excluir.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<ControladorAdmin>();
    final texto = Theme.of(context).textTheme;

    return ConteudoCentralizado(
      conteudo: Padding(
        padding: EdgeInsets.symmetric(vertical: context.ehComputador ? 48 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PAINEL ADMIN', style: texto.labelMedium),
                      const SizedBox(height: 4),
                      Text('PRODUTOS', style: texto.headlineLarge),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.push('/admin/produto/novo'),
                  icon: const Icon(Icons.add),
                  label: Text(context.ehCelular ? 'NOVO' : 'NOVO PRODUTO'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: admin.pesquisar,
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou categoria...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 20),
            if (admin.carregando)
              const Carregando()
            else if (admin.erro != null && admin.itens.isEmpty)
              MensagemFormulario(texto: admin.erro!)
            else if (admin.itens.isEmpty)
              const EstadoVazio(icone: Icons.inventory_2_outlined, titulo: 'Nenhum produto cadastrado')
            else
              for (final produto in admin.itens) ...[
                _ItemProdutoAdmin(
                  produto: produto,
                  aoDestacar: (v) => _marcar(produto, emDestaque: v),
                  aoMarcarNovidade: (v) => _marcar(produto, novidade: v),
                  aoEditar: () => context.push('/admin/produto/${produto.id}'),
                  aoExcluir: () => _excluir(produto),
                ),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Linha de um produto na lista do admin.
class _ItemProdutoAdmin extends StatelessWidget {
  const _ItemProdutoAdmin({
    required this.produto,
    required this.aoDestacar,
    required this.aoMarcarNovidade,
    required this.aoEditar,
    required this.aoExcluir,
  });

  final Produto produto;
  final ValueChanged<bool> aoDestacar;
  final ValueChanged<bool> aoMarcarNovidade;
  final VoidCallback aoEditar;
  final VoidCallback aoExcluir;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    final chaves = Wrap(
      spacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _ChaveComRotulo(rotulo: 'Destaque', valor: produto.emDestaque, aoMudar: aoDestacar),
        _ChaveComRotulo(rotulo: 'Novidade', valor: produto.novidade, aoMudar: aoMarcarNovidade),
      ],
    );

    final aviso = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(produto.titulo, style: texto.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(
          [
            produto.categoria,
            switch (produto.situacaoDesconto) {
              SituacaoDesconto.ativo => '${formatarMoeda(produto.precoFinal)} (-${produto.percentualDesconto}%)',
              SituacaoDesconto.agendado => '${formatarMoeda(produto.preco)} (-${produto.percentualDesconto}% agendado)',
              _ => formatarMoeda(produto.preco),
            },
            'estoque ${produto.estoque ?? 0}',
          ].join(' · '),
          style: texto.bodySmall,
        ),
        if (context.ehCelular) ...[const SizedBox(height: 8), chaves],
      ],
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TemaNice.raio),
        border: Border.all(color: TemaNice.cinzaSuave, width: 1.5),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 76,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(TemaNice.raio),
              child: ColoredBox(color: TemaNice.cinzaSuave, child: ImagemRede(url: produto.urlFoto)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: aviso),
          if (!context.ehCelular) ...[chaves, const SizedBox(width: 8)],
          IconButton(tooltip: 'Editar', icon: const Icon(Icons.edit_outlined), onPressed: aoEditar),
          IconButton(tooltip: 'Excluir', icon: const Icon(Icons.delete_outline), onPressed: aoExcluir),
        ],
      ),
    );
  }
}

/// Chave liga e desliga com um texto ao lado.
class _ChaveComRotulo extends StatelessWidget {
  const _ChaveComRotulo({required this.rotulo, required this.valor, required this.aoMudar});

  final String rotulo;
  final bool valor;
  final ValueChanged<bool> aoMudar;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(rotulo, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(width: 6),
        Switch(value: valor, onChanged: aoMudar),
      ],
    );
  }
}
