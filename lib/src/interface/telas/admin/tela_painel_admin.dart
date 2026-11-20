// Página inicial do painel do administrador.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/tema.dart';
import '../../componentes/responsivo.dart';

/// Um cartão do painel e a página que ele abre.
class _SecaoAdmin {
  const _SecaoAdmin(this.titulo, this.descricao, this.icone, this.caminho);

  final String titulo;
  final String descricao;
  final IconData icone;
  final String caminho;
}

/// Áreas do painel.
const _secoes = [
  _SecaoAdmin(
    'Produtos',
    'Lista, busca, destaque, novidade, edição e exclusão de produtos.',
    Icons.inventory_2_outlined,
    '/admin/produtos',
  ),
  _SecaoAdmin(
    'Cadastrar produto',
    'Novo produto com cores, fotos por cor, tamanhos e detalhes técnicos.',
    Icons.add_box_outlined,
    '/admin/produto/novo',
  ),
  _SecaoAdmin(
    'Descontos',
    'Descontos com data e hora de início e fim, aplicados ou cancelados em massa.',
    Icons.local_offer_outlined,
    '/admin/descontos',
  ),
  _SecaoAdmin(
    'Usuários',
    'Clientes cadastrados, endereços, histórico de pedidos e permissão de admin.',
    Icons.people_outline,
    '/admin/usuarios',
  ),
];

/// Mostra um cartão para cada área do painel.
class TelaPainelAdmin extends StatelessWidget {
  const TelaPainelAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return ConteudoCentralizado(
      conteudo: Padding(
        padding: EdgeInsets.symmetric(vertical: context.ehComputador ? 48 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('NICE', style: texto.labelMedium),
            const SizedBox(height: 4),
            Text('PAINEL ADMIN', style: texto.headlineLarge),
            const SizedBox(height: 28),
            LayoutBuilder(
              builder: (context, limites) {
                final colunas = limites.maxWidth >= 900 ? 3 : (limites.maxWidth >= 560 ? 2 : 1);
                final largura = (limites.maxWidth - (colunas - 1) * 16) / colunas;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final secao in _secoes) SizedBox(width: largura, child: _CartaoAdmin(secao: secao)),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Cartão clicável de uma área.
class _CartaoAdmin extends StatelessWidget {
  const _CartaoAdmin({required this.secao});

  final _SecaoAdmin secao;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Material(
      color: TemaNice.branco,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TemaNice.raio),
        side: const BorderSide(color: TemaNice.cinzaSuave, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(secao.caminho),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: TemaNice.vermelho,
                    child: Icon(secao.icone, color: TemaNice.branco),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_outward, color: TemaNice.vermelho),
                ],
              ),
              const SizedBox(height: 20),
              Text(secao.titulo.toUpperCase(), style: texto.titleLarge),
              const SizedBox(height: 6),
              Text(secao.descricao, style: texto.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
