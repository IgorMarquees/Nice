// Painel de descontos do administrador.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controladores/controlador_admin.dart';
import '../../../controladores/controlador_catalogo.dart';
import '../../../dados/produto.dart';
import '../../../nucleo/tema.dart';
import '../../../nucleo/avisos.dart';
import '../../../nucleo/formatadores.dart';
import '../../componentes/editor_desconto.dart';
import '../../componentes/imagem_rede.dart';
import '../../componentes/responsivo.dart';
import '../../componentes/estados_tela.dart';

/// Filtro da lista pela situação do desconto.
enum _FiltroSituacao {
  todos('Todos'),
  comDesconto('Com desconto'),
  semDesconto('Sem desconto');

  const _FiltroSituacao(this.rotulo);
  final String rotulo;
}

/// Seleciona vários produtos e aplica ou cancela o desconto de todos de uma vez.
class TelaDescontos extends StatefulWidget {
  const TelaDescontos({super.key});

  @override
  State<TelaDescontos> createState() => _TelaDescontosEstado();
}

class _TelaDescontosEstado extends State<TelaDescontos> {
  /// Ids dos produtos marcados.
  final Set<String> _selecionados = {};
  String _busca = '';
  String _categoria = ControladorCatalogo.todasCategorias;
  _FiltroSituacao _situacao = _FiltroSituacao.todos;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ControladorAdmin>().carregar();
    });
  }

  /// Produtos que passam na busca e nos filtros.
  List<Produto> _visiveis(List<Produto> todos) {
    final q = _busca.trim().toLowerCase();
    return todos.where((p) {
      final situacao = p.situacaoDesconto;
      final configurado = situacao == SituacaoDesconto.ativo || situacao == SituacaoDesconto.agendado;
      return (q.isEmpty || p.titulo.toLowerCase().contains(q)) &&
          (_categoria == ControladorCatalogo.todasCategorias || p.categoria == _categoria) &&
          switch (_situacao) {
            _FiltroSituacao.todos => true,
            _FiltroSituacao.comDesconto => configurado,
            _FiltroSituacao.semDesconto => !configurado,
          };
    }).toList();
  }

  /// Abre o diálogo e aplica o desconto nos produtos escolhidos.
  Future<void> _aplicar(List<String> ids, {Produto? unico}) async {
    final admin = context.read<ControladorAdmin>();
    final catalogo = context.read<ControladorCatalogo>();
    final entrada = await abrirDialogoDesconto(
      context,
      titulo: unico == null ? 'Desconto em ${ids.length} produto(s)' : 'Desconto: ${unico.titulo}',
      percentualInicial: unico != null && unico.percentualDesconto > 0 ? unico.percentualDesconto : 10,
      comecaEm: unico?.inicioDesconto,
      terminaEm: unico?.fimDesconto,
    );
    if (entrada == null || !mounted) return;
    final deuCerto = await admin.aplicarDesconto(ids, percentual: entrada.percentual, comecaEm: entrada.comecaEm, terminaEm: entrada.terminaEm);
    if (!mounted) return;
    if (deuCerto) {
      catalogo.carregar(forcar: true);
      setState(_selecionados.clear);
    }
    mostrarMensagem(context, deuCerto ? 'Desconto aplicado em ${ids.length} produto(s).' : (admin.erro ?? 'Erro.'));
  }

  /// Pede confirmação e tira o desconto dos produtos escolhidos.
  Future<void> _cancelar(List<String> ids) async {
    final admin = context.read<ControladorAdmin>();
    final catalogo = context.read<ControladorCatalogo>();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar desconto'),
        content: Text('Remover o desconto de ${ids.length} produto(s)? Eles voltam ao preço cheio na hora.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Voltar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancelar desconto')),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    final deuCerto = await admin.cancelarDesconto(ids);
    if (!mounted) return;
    if (deuCerto) {
      catalogo.carregar(forcar: true);
      setState(_selecionados.clear);
    }
    mostrarMensagem(context, deuCerto ? 'Desconto cancelado em ${ids.length} produto(s).' : (admin.erro ?? 'Erro.'));
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<ControladorAdmin>();
    final texto = Theme.of(context).textTheme;
    final visiveis = _visiveis(admin.todos);
    final idsVisiveis = visiveis.map((p) => p.id).toSet();
    _selecionados.removeWhere((id) => !admin.todos.any((p) => p.id == id));
    final todosSelecionados = visiveis.isNotEmpty && idsVisiveis.every(_selecionados.contains);
    final selecionado = _selecionados.toList();

    return ConteudoCentralizado(
      conteudo: Padding(
        padding: EdgeInsets.symmetric(vertical: context.ehComputador ? 48 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('PAINEL ADMIN', style: texto.labelMedium),
            const SizedBox(height: 4),
            Text('DESCONTOS', style: texto.headlineLarge),
            const SizedBox(height: 6),
            Text(
              'Selecione os produtos e aplique um desconto com data e hora de início e fim, ou cancele os descontos de vários de uma vez.',
              style: texto.bodySmall,
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: (v) => setState(() => _busca = v),
              decoration: const InputDecoration(hintText: 'Buscar produto...', prefixIcon: Icon(Icons.search)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final categoria in ControladorCatalogo.categorias)
                  ChoiceChip(
                    label: Text(categoria),
                    selected: _categoria == categoria,
                    labelStyle: TemaNice.rotuloChip(selecionado: _categoria == categoria),
                    onSelected: (_) => setState(() => _categoria = categoria),
                  ),
                const SizedBox(width: 8),
                for (final filtro in _FiltroSituacao.values)
                  ChoiceChip(
                    label: Text(filtro.rotulo),
                    selected: _situacao == filtro,
                    labelStyle: TemaNice.rotuloChip(selecionado: _situacao == filtro),
                    onSelected: (_) => setState(() => _situacao = filtro),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: TemaNice.cinzaClaro,
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: todosSelecionados,
                          onChanged: visiveis.isEmpty
                              ? null
                              : (v) => setState(() {
                                  v == true ? _selecionados.addAll(idsVisiveis) : _selecionados.removeAll(idsVisiveis);
                                }),
                        ),
                        Flexible(child: Text('Todos (${visiveis.length})', style: texto.bodyMedium)),
                      ],
                    ),
                  ),
                  Text('${selecionado.length} selecionado(s)', style: texto.titleSmall),
                  FilledButton.icon(
                    onPressed: selecionado.isEmpty || admin.salvando ? null : () => _aplicar(selecionado),
                    icon: const Icon(Icons.local_offer_outlined, size: 18),
                    label: const Text('APLICAR DESCONTO'),
                  ),
                  OutlinedButton.icon(
                    onPressed: selecionado.isEmpty || admin.salvando ? null : () => _cancelar(selecionado),
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('CANCELAR DESCONTO'),
                  ),
                  if (admin.salvando)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (admin.carregando && admin.todos.isEmpty)
              const Carregando()
            else if (admin.erro != null && admin.todos.isEmpty)
              MensagemFormulario(texto: admin.erro!)
            else if (visiveis.isEmpty)
              const EstadoVazio(icone: Icons.local_offer_outlined, titulo: 'Nenhum produto encontrado')
            else
              for (final produto in visiveis) ...[
                _ItemDesconto(
                  produto: produto,
                  selecionado: _selecionados.contains(produto.id),
                  aoMarcar: (v) => setState(() => v ? _selecionados.add(produto.id) : _selecionados.remove(produto.id)),
                  aoEditar: () => _aplicar([produto.id], unico: produto),
                  aoCancelar: () => _cancelar([produto.id]),
                ),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Linha de um produto com caixa de seleção situação e botões.
class _ItemDesconto extends StatelessWidget {
  const _ItemDesconto({
    required this.produto,
    required this.selecionado,
    required this.aoMarcar,
    required this.aoEditar,
    required this.aoCancelar,
  });

  final Produto produto;
  final bool selecionado;
  final ValueChanged<bool> aoMarcar;
  final VoidCallback aoEditar;
  final VoidCallback aoCancelar;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final situacao = produto.situacaoDesconto;
    final cancelavel = situacao == SituacaoDesconto.ativo || situacao == SituacaoDesconto.agendado;
    final precoComDesconto = produto.percentualDesconto > 0
        ? produto.preco * (100 - produto.percentualDesconto) / 100
        : produto.preco;

    return Material(
      color: selecionado ? TemaNice.cinzaClaro : TemaNice.branco,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TemaNice.raio),
        side: BorderSide(color: selecionado ? TemaNice.vermelho : TemaNice.cinzaSuave, width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(TemaNice.raio),
        onTap: () => aoMarcar(!selecionado),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
          child: Row(
            children: [
              Checkbox(value: selecionado, onChanged: (v) => aoMarcar(v ?? false)),
              SizedBox(
                width: 52,
                height: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(TemaNice.raio),
                  child: ColoredBox(
                    color: TemaNice.cinzaSuave,
                    child: ImagemRede(url: produto.urlFoto),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(produto.titulo, style: texto.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      produto.percentualDesconto > 0 && situacao != SituacaoDesconto.encerrado
                          ? '${formatarMoeda(produto.preco)} → ${formatarMoeda(precoComDesconto)}'
                          : formatarMoeda(produto.preco),
                      style: texto.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SeloSituacaoDesconto(situacao: situacao),
                        if (situacao != SituacaoDesconto.nenhum) Text(descreverDesconto(produto), style: texto.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: cancelavel ? 'Editar desconto' : 'Aplicar desconto',
                icon: const Icon(Icons.local_offer_outlined),
                onPressed: aoEditar,
              ),
              IconButton(
                tooltip: 'Cancelar desconto',
                icon: const Icon(Icons.block),
                onPressed: cancelavel ? aoCancelar : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
