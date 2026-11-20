import 'package:flutter/material.dart';

import '../../nucleo/tema.dart';

class _TopicoPolitica {
  const _TopicoPolitica(this.icone, this.titulo, this.itens);
  final IconData icone;
  final String titulo;
  final List<String> itens;
}

const _topicos = [
  _TopicoPolitica(Icons.swap_horiz, 'Troca de tamanho ou cor', [
    'Você tem até 30 dias corridos após o recebimento para trocar o tamanho ou a cor da peça.',
    'A primeira troca de cada pedido tem frete grátis: enviamos um código de postagem por e-mail.',
    'Se o tamanho ou a cor desejados acabarem, você recebe um vale-troca no valor pago, válido por 6 meses.',
  ]),
  _TopicoPolitica(Icons.undo, 'Arrependimento da compra', [
    'Pelo Código de Defesa do Consumidor, você pode desistir da compra em até 7 dias corridos após o recebimento.',
    'O reembolso é integral, incluindo o frete pago no pedido.',
  ]),
  _TopicoPolitica(Icons.checkroom, 'Condições da peça', [
    'A peça deve voltar sem sinais de uso, sem lavagem, sem odores e com a etiqueta NICE presa.',
    'Envie na embalagem original (ou em uma embalagem que proteja a peça).',
    'Peças em promoção também podem ser trocadas. Meias e acessórios de uso pessoal só são trocados em caso de defeito.',
  ]),
  _TopicoPolitica(Icons.report_gmailerrorred, 'Produto com defeito', [
    'Defeitos de fabricação podem ser informados em até 90 dias após o recebimento.',
    'Nossa equipe analisa a peça em até 5 dias úteis após a chegada e, confirmado o defeito, enviamos uma nova ou devolvemos o valor.',
    'Nesses casos, todos os fretes ficam por conta da NICE.',
  ]),
  _TopicoPolitica(Icons.mail_outline, 'Como solicitar', [
    'Envie um e-mail para trocas@nicestreetwear.com.br com o número do pedido (aparece em "Meus pedidos"), a peça e o motivo.',
    'Em até 2 dias úteis você recebe o código de postagem para levar o pacote a uma agência dos Correios.',
    'Acompanhe tudo pelo mesmo e-mail: avisamos quando a peça chegar e quando a troca ou o reembolso for concluído.',
  ]),
  _TopicoPolitica(Icons.payments_outlined, 'Reembolso', [
    'Pix e boleto: devolvido via Pix em até 5 dias úteis após a análise da peça.',
    'Cartão de crédito: estorno solicitado em até 5 dias úteis; o prazo para aparecer na fatura depende da operadora (até 2 faturas).',
  ]),
];

class PoliticaTrocas extends StatelessWidget {
  const PoliticaTrocas({super.key});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Na NICE, a peça certa é a que combina com você. Se não ficou bom, a gente resolve sem complicação.',
          style: texto.bodyMedium,
        ),
        const SizedBox(height: 12),
        for (final topico in _topicos)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: TemaNice.transparente),
            child: Column(
              children: [
                const Divider(),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(left: 40, bottom: 12),
                  leading: Icon(topico.icone, color: TemaNice.vermelho),
                  title: Text(topico.titulo, style: texto.titleSmall),
                  iconColor: TemaNice.vermelho,
                  collapsedIconColor: TemaNice.cinzaTexto,
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final item in topico.itens)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('•  ', style: texto.bodyMedium?.copyWith(color: TemaNice.vermelho)),
                            Expanded(child: Text(item, style: texto.bodyMedium)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
