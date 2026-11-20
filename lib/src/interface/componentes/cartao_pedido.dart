// Card de pedido.

import 'package:flutter/material.dart';

import '../../dados/pedido.dart';
import '../../nucleo/tema.dart';
import '../../nucleo/formatadores.dart';
import 'formulario_endereco.dart';

/// Mostra número data situação itens endereço e valores de um pedido.
class CartaoPedido extends StatelessWidget {
  const CartaoPedido({super.key, required this.pedido});

  final Pedido pedido;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TemaNice.raio),
        border: Border.all(color: TemaNice.cinzaSuave, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Pedido #${pedido.idCurto} · ${formatarData(pedido.criadoEm)}', style: texto.titleSmall),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: TemaNice.vermelho,
                child: Text(pedido.rotuloSituacao.toUpperCase(), style: texto.labelSmall?.copyWith(color: TemaNice.branco)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final item in pedido.itens)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${item.quantidade}x ${item.titulo}${item.tamanho.isEmpty ? '' : ' (${item.tamanho})'}',
                style: texto.bodyMedium,
              ),
            ),
          if (!pedido.endereco.vazio) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.local_shipping_outlined, size: 18, color: TemaNice.cinzaTexto),
                const SizedBox(width: 8),
                Expanded(child: ResumoEndereco(endereco: pedido.endereco, titulo: 'Entregue em')),
              ],
            ),
          ],
          const Divider(height: 24),
          if (pedido.desconto > 0 || pedido.frete > 0) ...[
            if (pedido.desconto > 0)
              Text('Desconto Pix: - ${formatarMoeda(pedido.desconto)}', style: texto.bodySmall),
            Text(
              'Frete: ${pedido.frete > 0 ? formatarMoeda(pedido.frete) : 'Grátis'}',
              style: texto.bodySmall,
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              Expanded(child: Text(pedido.formaPagamento.rotulo, style: texto.bodySmall)),
              const SizedBox(width: 12),
              Text(formatarMoeda(pedido.total), style: texto.titleSmall),
            ],
          ),
        ],
      ),
    );
  }
}
