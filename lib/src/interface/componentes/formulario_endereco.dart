// Formulário de endereço com busca pelo CEP.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controladores/controlador_enderecos.dart';
import '../../dados/pedido.dart';
import '../../nucleo/tema.dart';
import '../../nucleo/formatadores.dart';
import 'responsivo.dart';

/// Campos de endereço com CEP automático e UF obrigatória.
/// Use dentro de um Form e leia o resultado pelo valor do estado.
class CamposEndereco extends StatefulWidget {
  const CamposEndereco({super.key, this.inicial, this.destinatarioInicial = '', this.mostrarApelido = false});

  final EnderecoSalvo? inicial;
  final String destinatarioInicial;

  /// Mostra o campo de apelido usado nos endereços salvos.
  final bool mostrarApelido;

  @override
  State<CamposEndereco> createState() => CamposEnderecoEstado();
}

/// Guarda os campos digitados e a consulta de CEP.
class CamposEnderecoEstado extends State<CamposEndereco> {
  late final _apelido = TextEditingController(text: widget.inicial?.rotulo ?? '');
  late final _destinatario = TextEditingController(text: widget.inicial?.endereco.destinatario ?? widget.destinatarioInicial);
  late final _cep = TextEditingController(text: widget.inicial?.endereco.cep ?? '');
  late final _rua = TextEditingController(text: widget.inicial?.endereco.rua ?? '');
  late final _numero = TextEditingController(text: widget.inicial?.endereco.numero ?? '');
  late final _complemento = TextEditingController(text: widget.inicial?.endereco.complemento ?? '');
  late final _bairro = TextEditingController(text: widget.inicial?.endereco.bairro ?? '');
  late final _cidade = TextEditingController(text: widget.inicial?.endereco.cidade ?? '');
  final _focoNumero = FocusNode();
  late String? _uf = estadosBrasileiros.contains(widget.inicial?.endereco.estado) ? widget.inicial!.endereco.estado : null;

  bool _consultando = false;
  String? _mensagemCep;
  String _ultimaConsulta = '';

  List<TextEditingController> get _controladores =>
      [_apelido, _destinatario, _cep, _rua, _numero, _complemento, _bairro, _cidade];

  @override
  void dispose() {
    for (final c in _controladores) {
      c.dispose();
    }
    _focoNumero.dispose();
    super.dispose();
  }

  /// Endereço montado a partir dos campos.
  EnderecoSalvo get valor => EnderecoSalvo(
        id: widget.inicial?.id ?? '',
        rotulo: _apelido.text.trim(),
        endereco: EnderecoEntrega(
          destinatario: _destinatario.text.trim(),
          cep: _cep.text.trim(),
          rua: _rua.text.trim(),
          numero: _numero.text.trim(),
          complemento: _complemento.text.trim(),
          bairro: _bairro.text.trim(),
          cidade: _cidade.text.trim(),
          estado: _uf ?? '',
        ),
      );

  /// Quando o CEP fica completo consulta a API e preenche o resto.
  Future<void> _aoMudarCep(String valor) async {
    final digitos = valor.replaceAll(RegExp(r'\D'), '');
    if (digitos.length != 8 || digitos == _ultimaConsulta) return;
    _ultimaConsulta = digitos;
    setState(() {
      _consultando = true;
      _mensagemCep = null;
    });
    final resultado = await context.read<ControladorEnderecos>().consultarCep(digitos);
    if (!mounted) return;
    setState(() {
      _consultando = false;
      if (resultado == null) {
        _mensagemCep = 'CEP não encontrado. Preencha o endereço manualmente.';
        return;
      }
      if (resultado.rua.isNotEmpty) _rua.text = resultado.rua;
      if (resultado.bairro.isNotEmpty) _bairro.text = resultado.bairro;
      if (resultado.cidade.isNotEmpty) _cidade.text = resultado.cidade;
      if (estadosBrasileiros.contains(resultado.estado)) _uf = resultado.estado;
    });
    _focoNumero.requestFocus();
  }

  String? _obrigatorio(String? valor) => valor == null || valor.trim().isEmpty ? 'Obrigatório' : null;

  /// Campos lado a lado no computador e um embaixo do outro no celular.
  Widget _linha(List<Widget> campos, {List<int>? peso}) {
    if (context.ehCelular) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < campos.length; i++) ...[if (i > 0) const SizedBox(height: 12), campos[i]],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < campos.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(flex: peso?[i] ?? 1, child: campos[i]),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.mostrarApelido) ...[
          TextFormField(
            controller: _apelido,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Apelido (ex.: Casa, Trabalho)'),
          ),
          const SizedBox(height: 12),
        ],
        TextFormField(
          controller: _destinatario,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome do destinatário'),
          validator: _obrigatorio,
        ),
        const SizedBox(height: 12),
        _linha([
          TextFormField(
            controller: _cep,
            keyboardType: TextInputType.number,
            inputFormatters: [MascaraCep()],
            onChanged: _aoMudarCep,
            decoration: InputDecoration(
              labelText: 'CEP',
              suffixIcon: _consultando
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : const Icon(Icons.search, color: TemaNice.vermelho),
            ),
            validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length == 8 ? null : 'CEP inválido',
          ),
          DropdownButtonFormField<String>(
            key: ValueKey(_uf),
            initialValue: _uf,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'UF'),
            items: [for (final uf in estadosBrasileiros) DropdownMenuItem(value: uf, child: Text(uf))],
            onChanged: (v) => setState(() => _uf = v),
            validator: (v) => v == null ? 'Selecione a UF' : null,
          ),
        ]),
        if (_mensagemCep != null) ...[
          const SizedBox(height: 6),
          Text(_mensagemCep!, style: texto.bodySmall?.copyWith(color: TemaNice.vermelho)),
        ],
        const SizedBox(height: 12),
        _linha(
          [
            TextFormField(
              controller: _rua,
              decoration: const InputDecoration(labelText: 'Rua / Avenida'),
              validator: _obrigatorio,
            ),
            TextFormField(
              controller: _numero,
              focusNode: _focoNumero,
              decoration: const InputDecoration(labelText: 'Número'),
              validator: _obrigatorio,
            ),
          ],
          peso: const [3, 1],
        ),
        const SizedBox(height: 12),
        _linha([
          TextFormField(
            controller: _complemento,
            decoration: const InputDecoration(labelText: 'Complemento (opcional)'),
          ),
          TextFormField(
            controller: _bairro,
            decoration: const InputDecoration(labelText: 'Bairro'),
            validator: _obrigatorio,
          ),
        ]),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cidade,
          decoration: const InputDecoration(labelText: 'Cidade'),
          validator: _obrigatorio,
        ),
      ],
    );
  }
}

/// Abre o diálogo para cadastrar ou editar um endereço.
Future<EnderecoSalvo?> abrirDialogoEndereco(BuildContext context, {EnderecoSalvo? inicial, String destinatario = ''}) {
  return showDialog<EnderecoSalvo>(
    context: context,
    builder: (_) => _DialogoEndereco(inicial: inicial, destinatario: destinatario),
  );
}

class _DialogoEndereco extends StatefulWidget {
  const _DialogoEndereco({this.inicial, required this.destinatario});

  final EnderecoSalvo? inicial;
  final String destinatario;

  @override
  State<_DialogoEndereco> createState() => _DialogoEnderecoEstado();
}

/// Diálogo que salva o endereço no perfil.
class _DialogoEnderecoEstado extends State<_DialogoEndereco> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _campos = GlobalKey<CamposEnderecoEstado>();

  Future<void> _salvar() async {
    if (!_chaveFormulario.currentState!.validate()) return;
    final controlador = context.read<ControladorEnderecos>();
    final salvo = await controlador.salvar(_campos.currentState!.valor);
    if (!mounted) return;
    if (salvo != null) Navigator.pop(context, salvo);
  }

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<ControladorEnderecos>();
    return AlertDialog(
      title: Text(widget.inicial == null ? 'Novo endereço' : 'Editar endereço'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _chaveFormulario,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                CamposEndereco(
                  key: _campos,
                  inicial: widget.inicial,
                  destinatarioInicial: widget.destinatario,
                  mostrarApelido: true,
                ),
                if (controlador.erro != null) ...[
                  const SizedBox(height: 12),
                  Text(controlador.erro!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TemaNice.vermelho)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: controlador.salvando ? null : _salvar,
          child: controlador.salvando
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: TemaNice.branco))
              : const Text('Salvar'),
        ),
      ],
    );
  }
}

/// Endereço só para leitura usado no perfil pedidos e painel.
class ResumoEndereco extends StatelessWidget {
  const ResumoEndereco({super.key, required this.endereco, this.titulo});

  final EnderecoEntrega endereco;
  final String? titulo;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (titulo != null) Text(titulo!, style: texto.titleSmall),
        if (endereco.destinatario.isNotEmpty) Text(endereco.destinatario, style: texto.bodyMedium),
        Text(endereco.emUmaLinha, style: texto.bodySmall),
      ],
    );
  }
}
