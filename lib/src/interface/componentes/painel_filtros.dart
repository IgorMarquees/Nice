// Filtros do catálogo.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controladores/controlador_catalogo.dart';
import '../../nucleo/tema.dart';
import '../../nucleo/formatadores.dart';

/// Categoria tamanho preço máximo e ordenação.
/// Fica na lateral no computador e numa gaveta no celular.
class PainelFiltros extends StatelessWidget {
  const PainelFiltros({super.key});

  @override
  Widget build(BuildContext context) {
    final catalogo = context.watch<ControladorCatalogo>();
    final texto = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CATEGORIA', style: texto.labelMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final categoria in ControladorCatalogo.categorias)
              ChoiceChip(
                label: Text(categoria),
                selected: catalogo.categoriaSelecionada == categoria,
                labelStyle: TemaNice.rotuloChip(selecionado: catalogo.categoriaSelecionada == categoria),
                onSelected: (_) => catalogo.definirCategoria(categoria),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('TAMANHO', style: texto.labelMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tamanho in catalogo.tamanhosDisponiveis)
              ChoiceChip(
                label: Text(tamanho),
                selected: catalogo.tamanhoSelecionado == tamanho,
                labelStyle: TemaNice.rotuloChip(selecionado: catalogo.tamanhoSelecionado == tamanho),
                onSelected: (selecionado) => catalogo.definirTamanho(selecionado ? tamanho : null),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('PREÇO MÁXIMO', style: texto.labelMedium),
        Slider(
          value: catalogo.precoMaximo.clamp(0, catalogo.maiorPreco).toDouble(),
          min: 0,
          max: catalogo.maiorPreco,
          divisions: (catalogo.maiorPreco / 10).round().clamp(1, 100),
          onChanged: catalogo.definirPrecoMaximo,
        ),
        Text('Até ${formatarMoeda(catalogo.precoMaximo)}', style: texto.bodySmall),
        const SizedBox(height: 24),
        Text('ORDENAR POR', style: texto.labelMedium),
        const SizedBox(height: 10),
        DropdownButtonFormField<Ordenacao>(
          key: ValueKey(catalogo.ordenacao),
          initialValue: catalogo.ordenacao,
          items: [
            for (final opcao in Ordenacao.values)
              DropdownMenuItem(value: opcao, child: Text(opcao.rotulo)),
          ],
          onChanged: (valor) {
            if (valor != null) catalogo.definirOrdenacao(valor);
          },
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: catalogo.limparFiltros,
            child: const Text('Limpar filtros'),
          ),
        ),
      ],
    );
  }
}
