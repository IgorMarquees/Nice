import 'package:flutter/material.dart';

import '../../dados/produto.dart';
import '../../nucleo/tema.dart';
import '../../nucleo/formatadores.dart';

class DadosDesconto {
  const DadosDesconto({required this.percentual, this.comecaEm, this.terminaEm});

  final int percentual;

  /// Vazio quer dizer que começa na hora.
  final DateTime? comecaEm;

  /// Vazio quer dizer que não tem data para acabar.
  final DateTime? terminaEm;
}

/// Confere se o fim vem depois do início e ainda está no futuro.
String? validarPeriodoDesconto(DateTime? comecaEm, DateTime? terminaEm) {
  if (terminaEm == null) return null;
  if (comecaEm != null && !terminaEm.isAfter(comecaEm)) return 'O fim precisa ser depois do início.';
  if (!terminaEm.isAfter(DateTime.now())) return 'O fim precisa ser no futuro.';
  return null;
}

String descreverDesconto(Produto produto) {
  final inicio = produto.inicioDesconto;
  final fim = produto.fimDesconto;
  switch (produto.situacaoDesconto) {
    case SituacaoDesconto.nenhum:
      return 'Sem desconto';
    case SituacaoDesconto.agendado:
      return '-${produto.percentualDesconto}% · começa em ${formatarDataHora(inicio)}'
          '${fim == null ? '' : ' · termina em ${formatarDataHora(fim)}'}';
    case SituacaoDesconto.ativo:
      return '-${produto.percentualDesconto}% · ${fim == null ? 'sem data de término' : 'até ${formatarDataHora(fim)}'}';
    case SituacaoDesconto.encerrado:
      return '-${produto.percentualDesconto}% · encerrado em ${formatarDataHora(fim)}';
  }
}

class SeloSituacaoDesconto extends StatelessWidget {
  const SeloSituacaoDesconto({super.key, required this.situacao});

  final SituacaoDesconto situacao;

  @override
  Widget build(BuildContext context) {
    final cor = switch (situacao) {
      SituacaoDesconto.ativo => TemaNice.sucesso,
      SituacaoDesconto.agendado => TemaNice.vermelho,
      SituacaoDesconto.encerrado => TemaNice.cinzaMedio,
      SituacaoDesconto.nenhum => TemaNice.cinzaSuave,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: cor,
      child: Text(
        situacao.rotulo.toUpperCase(),
        style: TemaNice.selo().copyWith(color: situacao == SituacaoDesconto.nenhum ? TemaNice.grafite : TemaNice.branco),
      ),
    );
  }
}

class CampoDataHora extends StatelessWidget {
  const CampoDataHora({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.aoMudar,
    required this.textoVazio,
  });

  final String rotulo;
  final DateTime? valor;
  final ValueChanged<DateTime?> aoMudar;

  final String textoVazio;

  Future<void> _escolher(BuildContext context) async {
    final agora = DateTime.now();
    final inicial = valor ?? agora;
    final data = await showDatePicker(
      context: context,
      initialDate: inicial.isBefore(agora) ? agora : inicial,
      firstDate: DateTime(agora.year, agora.month, agora.day),
      lastDate: DateTime(agora.year + 3),
    );
    if (data == null || !context.mounted) return;
    final hora = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(inicial));
    if (hora == null) return;
    aoMudar(DateTime(data.year, data.month, data.day, hora.hour, hora.minute));
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => _escolher(context),
      borderRadius: BorderRadius.circular(TemaNice.raio),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: rotulo,
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: valor == null
              ? null
              : IconButton(tooltip: 'Limpar', icon: const Icon(Icons.close), onPressed: () => aoMudar(null)),
        ),
        child: Text(
          valor == null ? textoVazio : formatarDataHora(valor),
          style: valor == null ? texto.bodyMedium?.copyWith(color: TemaNice.cinzaTexto) : texto.bodyMedium,
        ),
      ),
    );
  }
}

Future<DadosDesconto?> abrirDialogoDesconto(
  BuildContext context, {
  required String titulo,
  int percentualInicial = 10,
  DateTime? comecaEm,
  DateTime? terminaEm,
}) {
  return showDialog<DadosDesconto>(
    context: context,
    builder: (_) => _DialogoDesconto(titulo: titulo, percentual: percentualInicial, comecaEm: comecaEm, terminaEm: terminaEm),
  );
}

class _DialogoDesconto extends StatefulWidget {
  const _DialogoDesconto({required this.titulo, required this.percentual, this.comecaEm, this.terminaEm});

  final String titulo;
  final int percentual;
  final DateTime? comecaEm;
  final DateTime? terminaEm;

  @override
  State<_DialogoDesconto> createState() => _DialogoDescontoEstado();
}

class _DialogoDescontoEstado extends State<_DialogoDesconto> {
  final _chaveFormulario = GlobalKey<FormState>();
  late final _percentual = TextEditingController(text: '${widget.percentual}');
  late DateTime? _comecaEm = widget.comecaEm;
  late DateTime? _terminaEm = widget.terminaEm;
  String? _erroPeriodo;

  @override
  void dispose() {
    _percentual.dispose();
    super.dispose();
  }

  void _confirmar() {
    final erroPeriodo = validarPeriodoDesconto(_comecaEm, _terminaEm);
    setState(() => _erroPeriodo = erroPeriodo);
    if (!_chaveFormulario.currentState!.validate() || erroPeriodo != null) return;
    Navigator.pop(
      context,
      DadosDesconto(percentual: int.parse(_percentual.text.trim()), comecaEm: _comecaEm, terminaEm: _terminaEm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text(widget.titulo),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _chaveFormulario,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                TextFormField(
                  controller: _percentual,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Desconto (%)', suffixText: '%'),
                  validator: validarPercentualDesconto,
                ),
                const SizedBox(height: 12),
                CampoDataHora(
                  rotulo: 'Início',
                  valor: _comecaEm,
                  textoVazio: 'Imediatamente',
                  aoMudar: (v) => setState(() => _comecaEm = v),
                ),
                const SizedBox(height: 12),
                CampoDataHora(
                  rotulo: 'Fim',
                  valor: _terminaEm,
                  textoVazio: 'Sem data de término',
                  aoMudar: (v) => setState(() => _terminaEm = v),
                ),
                if (_erroPeriodo != null) ...[
                  const SizedBox(height: 8),
                  Text(_erroPeriodo!, style: texto.bodySmall?.copyWith(color: TemaNice.vermelhoVivo)),
                ],
                const SizedBox(height: 8),
                Text('Horários no fuso deste dispositivo.', style: texto.bodySmall),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _confirmar, child: const Text('Aplicar')),
      ],
    );
  }
}

String? validarPercentualDesconto(String? valor) {
  final percentual = int.tryParse((valor ?? '').trim());
  return percentual == null || percentual < 1 || percentual > 90 ? 'Entre 1 e 90' : null;
}
