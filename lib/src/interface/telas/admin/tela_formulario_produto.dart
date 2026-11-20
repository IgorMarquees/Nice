import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../controladores/controlador_admin.dart';
import '../../../controladores/controlador_catalogo.dart';
import '../../../dados/produto.dart';
import '../../../nucleo/tema.dart';
import '../../../nucleo/avisos.dart';
import '../../../nucleo/formatadores.dart';
import '../../../nucleo/navegacao.dart';
import '../../componentes/editor_desconto.dart';
import '../../componentes/imagem_rede.dart';
import '../../componentes/responsivo.dart';
import '../../componentes/estados_tela.dart';

class _FotoEscolhida {
  _FotoEscolhida(this.arquivo, this.bytes);
  final XFile arquivo;
  final Uint8List bytes;
}

class _ConjuntoFotos {
  _ConjuntoFotos([List<String>? urls]) : urls = urls ?? [];

  final List<String> urls;
  final List<_FotoEscolhida> escolhidas = [];

  bool get vazio => urls.isEmpty && escolhidas.isEmpty;
}

class _RascunhoCor {
  _RascunhoCor({String nome = '', List<String>? urls})
      : nome = TextEditingController(text: nome),
        fotos = _ConjuntoFotos(urls);

  final TextEditingController nome;
  final _ConjuntoFotos fotos;
}

class TelaFormularioProduto extends StatefulWidget {
  const TelaFormularioProduto({super.key, this.idProduto});

  final String? idProduto;

  @override
  State<TelaFormularioProduto> createState() => _TelaFormularioProdutoEstado();
}

class _TelaFormularioProdutoEstado extends State<TelaFormularioProduto> {
  static final _categorias = ControladorCatalogo.categorias.skip(1).toList();

  final _chaveFormulario = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  final _tecnicos = TextEditingController();
  final _preco = TextEditingController();
  final _desconto = TextEditingController(text: '10');
  final _estoque = TextEditingController(text: '0');
  final _tamanhoPersonalizado = TextEditingController();

  String _categoria = _categorias.first;
  final List<String> _tamanhos = [];
  bool _emDestaque = false;
  bool _novidade = false;
  bool _temDesconto = false;
  DateTime? _inicioDesconto;
  DateTime? _fimDesconto;
  String? _erroDesconto;
  final _gerais = _ConjuntoFotos();
  final List<_RascunhoCor> _cores = [];

  Produto? _existente;
  bool _carregando = false;

  bool get _editando => widget.idProduto != null;

  @override
  void initState() {
    super.initState();
    if (_editando) {
      _carregando = true;
      _carregarExistente();
    }
  }

  Future<void> _carregarExistente() async {
    final produto = await context.read<ControladorAdmin>().encontrarPorId(widget.idProduto!);
    if (!mounted) return;
    setState(() {
      _existente = produto;
      if (produto != null) {
        _titulo.text = produto.titulo;
        _descricao.text = produto.descricao;
        _tecnicos.text = produto.detalhesTecnicos;
        _preco.text = produto.preco.toStringAsFixed(2).replaceAll('.', ',');
        _estoque.text = (produto.estoque ?? 0).toString();
        final situacao = produto.situacaoDesconto;
        _temDesconto = situacao == SituacaoDesconto.ativo || situacao == SituacaoDesconto.agendado;
        if (_temDesconto) {
          _desconto.text = produto.percentualDesconto.toString();
          _inicioDesconto = produto.inicioDesconto;
          _fimDesconto = produto.fimDesconto;
        }
        _categoria = _categorias.contains(produto.categoria) ? produto.categoria : _categorias.first;
        _tamanhos
          ..clear()
          ..addAll(produto.tamanhos);
        _emDestaque = produto.emDestaque;
        _novidade = produto.novidade;
        final fotosDasCores = {for (final c in produto.variantesCor) ...c.fotos};
        _gerais.urls.addAll(produto.fotos.where((url) => !fotosDasCores.contains(url)));
        for (final variante in produto.variantesCor) {
          _cores.add(_RascunhoCor(nome: variante.nome, urls: [...variante.fotos]));
        }
      }
      _carregando = false;
    });
  }

  @override
  void dispose() {
    for (final c in [_titulo, _descricao, _tecnicos, _preco, _desconto, _estoque, _tamanhoPersonalizado]) {
      c.dispose();
    }
    for (final cor in _cores) {
      cor.nome.dispose();
    }
    super.dispose();
  }

  Future<void> _escolherFotos(_ConjuntoFotos alvo) async {
    final arquivos = await ImagePicker().pickMultiImage(imageQuality: 85, maxWidth: 1800);
    final escolhidas = <_FotoEscolhida>[];
    for (final arquivo in arquivos) {
      escolhidas.add(_FotoEscolhida(arquivo, await arquivo.readAsBytes()));
    }
    if (!mounted) return;
    setState(() => alvo.escolhidas.addAll(escolhidas));
  }

  void _adicionarTamanho() {
    final valor = _tamanhoPersonalizado.text.trim();
    if (valor.isEmpty) return;
    setState(() {
      if (!_tamanhos.any((s) => s.toLowerCase() == valor.toLowerCase())) _tamanhos.add(valor);
      _tamanhoPersonalizado.clear();
    });
  }

  void _alternarTamanho(String tamanho, bool selecionado) {
    setState(() {
      if (!selecionado) {
        _tamanhos.remove(tamanho);
      } else if (!_tamanhos.contains(tamanho)) {
        _tamanhos.add(tamanho);
      }
    });
  }

  void _removerCor(int indice) {
    setState(() => _cores.removeAt(indice).nome.dispose());
  }

  /// Tamanhos padrão primeiro e depois os personalizados.
  List<String> get _tamanhosOrdenados => [
        ...ControladorCatalogo.tamanhos.where(_tamanhos.contains),
        ..._tamanhos.where((s) => !ControladorCatalogo.tamanhos.contains(s)),
      ];

  Future<void> _salvar() async {
    final erroPeriodo = _temDesconto ? validarPeriodoDesconto(_inicioDesconto, _fimDesconto) : null;
    setState(() => _erroDesconto = erroPeriodo);
    if (!_chaveFormulario.currentState!.validate() || erroPeriodo != null) return;
    final admin = context.read<ControladorAdmin>();
    final catalogo = context.read<ControladorCatalogo>();

    final nomes = [for (final c in _cores) c.nome.text.trim().toLowerCase()];
    if (nomes.toSet().length != nomes.length) {
      mostrarMensagem(context, 'Há cores com o mesmo nome.');
      return;
    }
    if (_gerais.vazio && _cores.every((c) => c.fotos.vazio)) {
      mostrarMensagem(context, 'Adicione pelo menos uma foto.');
      return;
    }

    final produto = Produto(
      id: _existente?.id ?? '',
      titulo: _titulo.text.trim(),
      descricao: _descricao.text.trim(),
      detalhesTecnicos: _tecnicos.text.trim(),
      preco: double.parse(_preco.text.trim().replaceAll(',', '.')),
      percentualDesconto: _temDesconto ? int.parse(_desconto.text.trim()) : 0,
      inicioDesconto: _temDesconto ? _inicioDesconto : null,
      fimDesconto: _temDesconto ? _fimDesconto : null,
      categoria: _categoria,
      fotos: _gerais.urls,
      tamanhos: _tamanhosOrdenados,
      estoque: int.parse(_estoque.text.trim()),
      emDestaque: _emDestaque,
      novidade: _novidade,
    );

    final deuCerto = await admin.salvar(
      produto,
      novasFotos: [for (final p in _gerais.escolhidas) p.arquivo],
      variantes: [
        for (final c in _cores)
          RascunhoVariante(
            nome: c.nome.text.trim(),
            fotos: c.fotos.urls,
            novosArquivos: [for (final p in c.fotos.escolhidas) p.arquivo],
          ),
      ],
    );
    if (!mounted) return;
    if (deuCerto) {
      catalogo.carregar(forcar: true);
      mostrarMensagem(context, 'Produto salvo.');
      context.go('/admin/produtos');
    } else {
      mostrarMensagem(context, admin.erro ?? 'Erro ao salvar.');
    }
  }

  Widget _par(Widget a, Widget b) {
    if (context.ehCelular) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, const SizedBox(height: 12), b]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Carregando();
    if (_editando && _existente == null) {
      return EstadoVazio(
        icone: Icons.search_off,
        titulo: 'Produto não encontrado',
        textoAcao: 'Voltar',
        aoAgir: () => context.go('/admin/produtos'),
      );
    }

    final admin = context.watch<ControladorAdmin>();
    final texto = Theme.of(context).textTheme;
    String? obrigatorio(String? v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null;
    final preco = double.tryParse(_preco.text.trim().replaceAll(',', '.'));
    final percentual = int.tryParse(_desconto.text.trim());
    final tamanhosPersonalizados = _tamanhos.where((s) => !ControladorCatalogo.tamanhos.contains(s)).toList();

    return ConteudoCentralizado(
      larguraMaxima: 900,
      conteudo: Padding(
        padding: EdgeInsets.symmetric(vertical: context.ehComputador ? 48 : 8),
        child: Form(
          key: _chaveFormulario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('PAINEL ADMIN', style: texto.labelMedium),
              const SizedBox(height: 4),
              Text(_editando ? 'EDITAR PRODUTO' : 'NOVO PRODUTO', style: texto.headlineLarge),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titulo,
                decoration: const InputDecoration(labelText: 'Nome do produto'),
                validator: obrigatorio,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descricao,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Descrição'),
                validator: obrigatorio,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tecnicos,
                minLines: 3,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Detalhes técnicos (opcional)',
                  hintText: 'Um item por linha. Ex.:\nComposição: 100% algodão\nGramatura: 240 g/m²\nModelagem: oversized',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              _par(
                TextFormField(
                  controller: _preco,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Preço (R\$)'),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final valor = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                    return valor == null || valor < 0 ? 'Preço inválido' : null;
                  },
                ),
                TextFormField(
                  controller: _estoque,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantidade em estoque'),
                  validator: (v) {
                    final valor = int.tryParse((v ?? '').trim());
                    return valor == null || valor < 0 ? 'Número inválido' : null;
                  },
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ativar desconto'),
                subtitle: const Text(
                  'Durante o período, o preço cheio aparece riscado e o produto ganha a etiqueta de desconto. '
                  'Para vários produtos de uma vez, use o painel "Descontos".',
                ),
                value: _temDesconto,
                onChanged: (v) => setState(() => _temDesconto = v),
              ),
              if (_temDesconto)
                _par(
                  TextFormField(
                    controller: _desconto,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Desconto (%)', suffixText: '%'),
                    onChanged: (_) => setState(() {}),
                    validator: validarPercentualDesconto,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      preco != null && percentual != null && percentual > 0 && percentual <= 90
                          ? 'Preço com desconto: ${formatarMoeda(preco * (100 - percentual) / 100)}'
                          : 'Informe preço e desconto',
                      style: texto.titleSmall,
                    ),
                  ),
                ),
              if (_temDesconto) ...[
                const SizedBox(height: 12),
                _par(
                  CampoDataHora(
                    rotulo: 'Início do desconto',
                    valor: _inicioDesconto,
                    textoVazio: 'Imediatamente',
                    aoMudar: (v) => setState(() => _inicioDesconto = v),
                  ),
                  CampoDataHora(
                    rotulo: 'Fim do desconto',
                    valor: _fimDesconto,
                    textoVazio: 'Sem data de término',
                    aoMudar: (v) => setState(() => _fimDesconto = v),
                  ),
                ),
                if (_erroDesconto != null) ...[
                  const SizedBox(height: 6),
                  Text(_erroDesconto!, style: texto.bodySmall?.copyWith(color: TemaNice.vermelhoVivo)),
                ],
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _categoria,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: [for (final c in _categorias) DropdownMenuItem(value: c, child: Text(c))],
                onChanged: (v) => setState(() => _categoria = v ?? _categoria),
              ),
              const SizedBox(height: 24),
              Text('TAMANHOS DISPONÍVEIS', style: texto.labelMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tamanho in ControladorCatalogo.tamanhos)
                    FilterChip(
                      label: Text(tamanho),
                      selected: _tamanhos.contains(tamanho),
                      selectedColor: TemaNice.vermelho,
                      labelStyle: TemaNice.rotuloChip(selecionado: _tamanhos.contains(tamanho)),
                      onSelected: (selecionado) => _alternarTamanho(tamanho, selecionado),
                    ),
                  for (final tamanho in tamanhosPersonalizados)
                    InputChip(
                      label: Text(tamanho),
                      selected: true,
                      selectedColor: TemaNice.vermelho,
                      labelStyle: TemaNice.rotuloChip(selecionado: true),
                      deleteIconColor: TemaNice.branco,
                      onDeleted: () => setState(() => _tamanhos.remove(tamanho)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tamanhoPersonalizado,
                      decoration: const InputDecoration(
                        hintText: 'Outro tamanho (ex.: 38, 40, Infantil)',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _adicionarTamanho(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _adicionarTamanho,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Exibir em Destaque na Home'),
                value: _emDestaque,
                onChanged: (v) => setState(() => _emDestaque = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Exibir em Novidades'),
                value: _novidade,
                onChanged: (v) => setState(() => _novidade = v),
              ),
              const SizedBox(height: 16),
              Text('CORES', style: texto.labelMedium),
              const SizedBox(height: 4),
              Text(
                'Cadastre cada cor separadamente, com as próprias fotos. Na loja, ao escolher a cor, a foto grande muda para a dessa cor.',
                style: texto.bodySmall,
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _cores.length; i++) ...[
                _CartaoCor(
                  key: ObjectKey(_cores[i]),
                  rascunho: _cores[i],
                  aoEscolher: () => _escolherFotos(_cores[i].fotos),
                  aoRemover: () => _removerCor(i),
                  aoMudar: () => setState(() {}),
                ),
                const SizedBox(height: 12),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _cores.add(_RascunhoCor())),
                  icon: const Icon(Icons.palette_outlined),
                  label: const Text('Adicionar cor'),
                ),
              ),
              const SizedBox(height: 24),
              Text(_cores.isEmpty ? 'FOTOS' : 'FOTOS GERAIS (OPCIONAL)', style: texto.labelMedium),
              const SizedBox(height: 4),
              Text(
                _cores.isEmpty
                    ? 'Produto sem variação de cor: adicione as fotos aqui.'
                    : 'Fotos que valem para todas as cores (ex.: detalhes, etiqueta).',
                style: texto.bodySmall,
              ),
              const SizedBox(height: 10),
              _GradeFotos(
                fotos: _gerais,
                aoEscolher: () => _escolherFotos(_gerais),
                aoMudar: () => setState(() {}),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: admin.salvando ? null : () => context.voltarOu('/admin/produtos'),
                      child: const Text('CANCELAR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: admin.salvando ? null : _salvar,
                      child: admin.salvando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: TemaNice.branco),
                            )
                          : const Text('SALVAR PRODUTO'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartaoCor extends StatelessWidget {
  const _CartaoCor({
    super.key,
    required this.rascunho,
    required this.aoEscolher,
    required this.aoRemover,
    required this.aoMudar,
  });

  final _RascunhoCor rascunho;
  final VoidCallback aoEscolher;
  final VoidCallback aoRemover;
  final VoidCallback aoMudar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TemaNice.raio),
        border: Border.all(color: TemaNice.cinzaSuave, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: rascunho.nome,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Nome da cor (ex.: Preto)'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome da cor' : null,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(tooltip: 'Remover cor', icon: const Icon(Icons.delete_outline), onPressed: aoRemover),
            ],
          ),
          const SizedBox(height: 12),
          _GradeFotos(fotos: rascunho.fotos, aoEscolher: aoEscolher, aoMudar: aoMudar),
        ],
      ),
    );
  }
}

class _GradeFotos extends StatelessWidget {
  const _GradeFotos({required this.fotos, required this.aoEscolher, required this.aoMudar});

  final _ConjuntoFotos fotos;
  final VoidCallback aoEscolher;
  final VoidCallback aoMudar;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < fotos.urls.length; i++)
          _Miniatura(
            conteudo: ImagemRede(url: fotos.urls[i], ajuste: BoxFit.cover),
            aoRemover: () {
              fotos.urls.removeAt(i);
              aoMudar();
            },
          ),
        for (var i = 0; i < fotos.escolhidas.length; i++)
          _Miniatura(
            conteudo: Image.memory(fotos.escolhidas[i].bytes, fit: BoxFit.cover),
            aoRemover: () {
              fotos.escolhidas.removeAt(i);
              aoMudar();
            },
          ),
        Tooltip(
          message: 'Adicionar fotos',
          child: InkWell(
            onTap: aoEscolher,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: TemaNice.cinzaClaro,
                borderRadius: BorderRadius.circular(TemaNice.raio),
                border: Border.all(color: TemaNice.cinzaSuave, width: 1.5),
              ),
              child: const Icon(Icons.add_photo_alternate_outlined, color: TemaNice.vermelho),
            ),
          ),
        ),
      ],
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.conteudo, required this.aoRemover});

  final Widget conteudo;
  final VoidCallback aoRemover;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(borderRadius: BorderRadius.circular(TemaNice.raio), child: conteudo),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: Material(
              color: TemaNice.grafite,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: aoRemover,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: TemaNice.branco),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
