// Tela de finalizar compra.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../nucleo/configuracao.dart';
import '../../controladores/controlador_enderecos.dart';
import '../../controladores/controlador_autenticacao.dart';
import '../../controladores/controlador_carrinho.dart';
import '../../controladores/controlador_pedidos.dart';
import '../../dados/pedido.dart';
import '../../nucleo/tema.dart';
import '../../nucleo/avisos.dart';
import '../../nucleo/formatadores.dart';
import '../componentes/formulario_endereco.dart';
import '../componentes/responsivo.dart';
import '../componentes/estados_tela.dart';

/// Endereço forma de pagamento e resumo do pedido.
class TelaFinalizarCompra extends StatefulWidget {
  const TelaFinalizarCompra({super.key});

  @override
  State<TelaFinalizarCompra> createState() => _TelaFinalizarCompraEstado();
}

class _TelaFinalizarCompraEstado extends State<TelaFinalizarCompra> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _campos = GlobalKey<CamposEnderecoEstado>();
  FormaPagamento _pagamento = FormaPagamento.pix;

  /// Endereço salvo escolhido.
  /// Vazio quer dizer que o cliente vai digitar outro.
  String? _idSelecionado;
  bool _escolheuManual = false;
  bool _salvarNovo = true;

  /// O primeiro endereço salvo já vem marcado até o cliente escolher outro.
  String? _selecaoAtual(List<EnderecoSalvo> salvo) {
    if (_escolheuManual) return _idSelecionado;
    return salvo.isEmpty ? null : salvo.first.id;
  }

  /// Monta o pedido grava no banco e limpa o carrinho.
  Future<void> _confirmar() async {
    final idUsuario = context.read<ControladorAutenticacao>().usuario?.id;
    if (idUsuario == null) return;

    final carrinho = context.read<ControladorCarrinho>();
    final pedidos = context.read<ControladorPedidos>();
    final enderecos = context.read<ControladorEnderecos>();
    final idSelecionado = _selecaoAtual(enderecos.itens);

    EnderecoEntrega endereco;
    if (idSelecionado != null) {
      endereco = enderecos.itens.firstWhere((a) => a.id == idSelecionado).endereco;
    } else {
      if (!_chaveFormulario.currentState!.validate()) return;
      final digitado = _campos.currentState!.valor;
      endereco = digitado.endereco;
      if (_salvarNovo) await enderecos.salvar(digitado);
    }
    if (!mounted) return;

    final deuCerto = await pedidos.fazerPedido(
      idUsuario: idUsuario,
      itens: carrinho.itens,
      totais: TotaisPedido.calcular(carrinho.total, _pagamento),
      formaPagamento: _pagamento,
      endereco: endereco,
    );

    if (!mounted) return;
    if (deuCerto) {
      carrinho.limpar();
      mostrarMensagem(context, 'Pedido realizado com sucesso!');
      context.go('/perfil');
    } else {
      mostrarMensagem(context, pedidos.erro ?? 'Não foi possível finalizar a compra.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final carrinho = context.watch<ControladorCarrinho>();
    final pedidos = context.watch<ControladorPedidos>();
    final enderecos = context.watch<ControladorEnderecos>();
    final usuario = context.watch<ControladorAutenticacao>().usuario;
    final texto = Theme.of(context).textTheme;

    if (carrinho.vazio) {
      return EstadoVazio(
        icone: Icons.shopping_bag_outlined,
        titulo: 'Seu carrinho está vazio',
        textoAcao: 'Ver catálogo',
        aoAgir: () => context.go('/catalogo'),
      );
    }

    final idSelecionado = _selecaoAtual(enderecos.itens);
    final totais = TotaisPedido.calcular(carrinho.total, _pagamento);

    final formulario = Form(
      key: _chaveFormulario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('FINALIZAR COMPRA', style: texto.headlineLarge),
          const SizedBox(height: 24),
          Text('ENDEREÇO DE ENTREGA', style: texto.labelMedium),
          const SizedBox(height: 12),
          if (enderecos.carregando && enderecos.itens.isEmpty)
            const LinearProgressIndicator()
          else ...[
            for (final salvo in enderecos.itens) ...[
              _CartaoSelecionavel(
                selecionado: idSelecionado == salvo.id,
                aoTocar: () => setState(() {
                  _escolheuManual = true;
                  _idSelecionado = salvo.id;
                }),
                conteudo: ResumoEndereco(endereco: salvo.endereco, titulo: salvo.titulo),
              ),
              const SizedBox(height: 10),
            ],
            if (enderecos.itens.isNotEmpty)
              _CartaoSelecionavel(
                selecionado: idSelecionado == null,
                aoTocar: () => setState(() {
                  _escolheuManual = true;
                  _idSelecionado = null;
                }),
                conteudo: Text('Usar outro endereço', style: texto.titleSmall),
              ),
            if (idSelecionado == null) ...[
              const SizedBox(height: 16),
              CamposEndereco(key: _campos, destinatarioInicial: usuario?.nome ?? '', mostrarApelido: _salvarNovo),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _salvarNovo,
                onChanged: (v) => setState(() => _salvarNovo = v ?? false),
                title: const Text('Salvar este endereço no meu perfil'),
              ),
            ],
          ],
          const SizedBox(height: 28),
          Text('FORMA DE PAGAMENTO', style: texto.labelMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final forma in FormaPagamento.values)
                ChoiceChip(
                  label: Text(forma == FormaPagamento.pix
                      ? '${forma.rotulo} (-${(Configuracao.descontoPix * 100).round()}%)'
                      : forma.rotulo),
                  selected: _pagamento == forma,
                  labelStyle: TemaNice.rotuloChip(selecionado: _pagamento == forma),
                  onSelected: (_) => setState(() => _pagamento = forma),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Pagando no Pix você ganha ${(Configuracao.descontoPix * 100).round()}% de desconto no valor dos produtos.',
            style: texto.bodySmall,
          ),
        ],
      ),
    );

    Widget linha(String rotulo, String valor, {TextStyle? estilo}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(child: Text(rotulo, style: texto.bodyMedium)),
              const SizedBox(width: 12),
              Text(valor, style: estilo ?? texto.bodyMedium),
            ],
          ),
        );

    final resumo = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TemaNice.cinzaClaro,
        borderRadius: BorderRadius.circular(TemaNice.raio),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('SEU PEDIDO', style: texto.titleLarge),
          const SizedBox(height: 16),
          for (final item in carrinho.itens)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantidade}x ${item.titulo}${item.tamanho.isEmpty ? '' : ' (${item.tamanho})'}',
                      style: texto.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(formatarMoeda(item.subtotal), style: texto.bodyMedium),
                ],
              ),
            ),
          const Divider(height: 28),
          linha('Produtos', formatarMoeda(totais.subtotal)),
          if (totais.desconto > 0)
            linha(
              'Desconto Pix (${(Configuracao.descontoPix * 100).round()}%)',
              '- ${formatarMoeda(totais.desconto)}',
              estilo: texto.bodyMedium?.copyWith(color: TemaNice.sucesso),
            ),
          linha(
            'Frete',
            totais.freteGratis ? 'Grátis' : formatarMoeda(totais.frete),
            estilo: totais.freteGratis ? texto.bodyMedium?.copyWith(color: TemaNice.sucesso) : null,
          ),
          if (!totais.freteGratis)
            Text(
              'Frete grátis a partir de ${formatarMoeda(Configuracao.freteGratisAPartirDe)}.',
              style: texto.bodySmall,
            ),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(child: Text('Total', style: texto.titleLarge)),
              const SizedBox(width: 12),
              Text(formatarMoeda(totais.total), style: texto.headlineSmall?.copyWith(color: TemaNice.vermelho)),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: pedidos.enviando || enderecos.salvando ? null : _confirmar,
            icon: pedidos.enviando
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: TemaNice.branco))
                : const Icon(Icons.lock_outline),
            label: const Text('CONFIRMAR PEDIDO'),
          ),
        ],
      ),
    );

    return ConteudoCentralizado(
      conteudo: Padding(
        padding: EdgeInsets.symmetric(vertical: context.ehComputador ? 48 : 8),
        child: context.ehComputador
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: formulario),
                  const SizedBox(width: 40),
                  SizedBox(width: 380, child: resumo),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [formulario, const SizedBox(height: 28), resumo, const SizedBox(height: 32)],
              ),
      ),
    );
  }
}

/// Cartão que pode ser marcado como uma opção de escolha.
class _CartaoSelecionavel extends StatelessWidget {
  const _CartaoSelecionavel({required this.selecionado, required this.aoTocar, required this.conteudo});

  final bool selecionado;
  final VoidCallback aoTocar;
  final Widget conteudo;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: aoTocar,
      borderRadius: BorderRadius.circular(TemaNice.raio),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TemaNice.raio),
          border: Border.all(color: selecionado ? TemaNice.vermelho : TemaNice.cinzaSuave, width: selecionado ? 2 : 1.5),
        ),
        child: Row(
          children: [
            Icon(
              selecionado ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selecionado ? TemaNice.vermelho : TemaNice.cinzaMedio,
            ),
            const SizedBox(width: 12),
            Expanded(child: conteudo),
          ],
        ),
      ),
    );
  }
}
