import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../nucleo/configuracao.dart';
import '../../controladores/controlador_carrinho.dart';
import '../../dados/item_carrinho.dart';
import '../../dados/pedido.dart';
import '../../nucleo/tema.dart';
import '../../nucleo/formatadores.dart';
import '../componentes/imagem_rede.dart';
import '../componentes/responsivo.dart';
import '../componentes/estados_tela.dart';

class TelaCarrinho extends StatelessWidget {
  const TelaCarrinho({super.key});

  @override
  Widget build(BuildContext context) {
    final carrinho = context.watch<ControladorCarrinho>();
    final texto = Theme.of(context).textTheme;

    if (carrinho.vazio) {
      return EstadoVazio(
        icone: Icons.shopping_bag_outlined,
        titulo: 'Seu carrinho está vazio',
        mensagem: 'Adicione peças pela Home ou pelo catálogo.',
        textoAcao: 'Ver catálogo',
        aoAgir: () => context.go('/catalogo'),
      );
    }

    final lista = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('CARRINHO', style: texto.headlineLarge)),
            TextButton(onPressed: carrinho.limpar, child: const Text('Limpar')),
          ],
        ),
        const SizedBox(height: 16),
        for (final item in carrinho.itens) ...[
          _LinhaCarrinho(item: item),
          const SizedBox(height: 14),
        ],
      ],
    );
    const resumo = _ResumoPedido();

    return ConteudoCentralizado(
      conteudo: Padding(
        padding: EdgeInsets.symmetric(vertical: context.ehComputador ? 48 : 8),
        child: context.ehComputador
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: lista),
                  const SizedBox(width: 40),
                  const SizedBox(width: 380, child: resumo),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [lista, resumo, const SizedBox(height: 32)],
              ),
      ),
    );
  }
}

class _ResumoPedido extends StatelessWidget {
  const _ResumoPedido();

  @override
  Widget build(BuildContext context) {
    final carrinho = context.watch<ControladorCarrinho>();
    final texto = Theme.of(context).textTheme;
    final totais = TotaisPedido.calcular(carrinho.total, FormaPagamento.cartao);
    final pix = TotaisPedido.calcular(carrinho.total, FormaPagamento.pix);
    final faltando = Configuracao.freteGratisAPartirDe - carrinho.total;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TemaNice.branco,
        borderRadius: BorderRadius.circular(TemaNice.raio),
        border: Border.all(color: TemaNice.cinzaSuave, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('RESUMO DO PEDIDO', style: texto.titleLarge),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Text('Itens (${carrinho.qtdItens})', style: texto.bodyMedium)),
              const SizedBox(width: 12),
              Text(formatarMoeda(carrinho.total), style: texto.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text('Frete', style: texto.bodyMedium)),
              const SizedBox(width: 12),
              Text(
                totais.freteGratis ? 'Grátis' : formatarMoeda(totais.frete),
                style: texto.bodyMedium?.copyWith(color: totais.freteGratis ? TemaNice.sucesso : null),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            faltando > 0
                ? 'Faltam ${formatarMoeda(faltando)} para ganhar frete grátis.'
                : 'Você ganhou frete grátis!',
            style: texto.bodySmall,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: (carrinho.total / Configuracao.freteGratisAPartirDe).clamp(0, 1).toDouble(),
            backgroundColor: TemaNice.cinzaSuave,
            minHeight: 4,
          ),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(child: Text('Total', style: texto.titleLarge)),
              const SizedBox(width: 12),
              Text(formatarMoeda(totais.total), style: texto.headlineSmall?.copyWith(color: TemaNice.vermelho)),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'ou ${formatarMoeda(pix.total)} no Pix (5% de desconto)',
              style: texto.bodySmall?.copyWith(color: TemaNice.sucesso),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.go('/checkout'),
            icon: const Icon(Icons.lock_outline),
            label: const Text('FINALIZAR COMPRA'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/catalogo'),
            child: const Text('Continuar comprando'),
          ),
        ],
      ),
    );
  }
}

class _LinhaCarrinho extends StatelessWidget {
  const _LinhaCarrinho({required this.item});

  final ItemCarrinho item;

  @override
  Widget build(BuildContext context) {
    final carrinho = context.read<ControladorCarrinho>();
    final texto = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TemaNice.cinzaClaro,
        borderRadius: BorderRadius.circular(TemaNice.raio),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(TemaNice.raio),
              child: ColoredBox(color: TemaNice.cinzaSuave, child: ImagemRede(url: item.urlFoto)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.titulo, style: texto.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (item.tamanho.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Variação: ${item.tamanho}', style: texto.bodySmall),
                ],
                const SizedBox(height: 4),
                Text('${formatarMoeda(item.precoUnitario)} un.', style: texto.bodySmall),
                const SizedBox(height: 8),
                Text(formatarMoeda(item.subtotal), style: texto.titleSmall),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: 'Remover',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => carrinho.remover(item),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Diminuir',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => carrinho.diminuir(item),
                  ),
                  Text('${item.quantidade}', style: texto.titleSmall),
                  IconButton(
                    tooltip: 'Aumentar',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => carrinho.aumentar(item),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
