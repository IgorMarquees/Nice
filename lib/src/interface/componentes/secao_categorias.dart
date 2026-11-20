import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controladores/controlador_catalogo.dart';
import '../../nucleo/tema.dart';
import '../../nucleo/navegacao.dart';
import 'imagem_rede.dart';
import 'responsivo.dart';

const _iconesCategorias = <String, IconData>{
  'Camisetas': Icons.checkroom,
  'Moletons': Icons.dry_cleaning,
  'Calças': Icons.straighten,
  'Acessórios': Icons.watch_outlined,
};

/// Abre o catálogo filtrado pela categoria já rolado até os produtos.
void abrirCategoria(BuildContext context, String categoria) =>
    context.go(caminhoCatalogo(categoria: categoria, irParaProdutos: true));

class SecaoCategorias extends StatelessWidget {
  const SecaoCategorias({super.key});

  @override
  Widget build(BuildContext context) {
    final nomes = ControladorCatalogo.categorias.skip(1).toList();

    if (context.ehCelular) {
      return SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: nomes.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, indice) => ActionChip(
            avatar: Icon(_iconesCategorias[nomes[indice]], size: 18, color: TemaNice.vermelho),
            label: Text(nomes[indice]),
            onPressed: () => abrirCategoria(context, nomes[indice]),
          ),
        ),
      );
    }

    final catalogo = context.watch<ControladorCatalogo>();
    final colunas = context.ehComputador ? 4 : 2;
    const formato = 1.35;
    const grande = false;

    final registros = <Widget>[];
    for (var inicio = 0; inicio < nomes.length; inicio += colunas) {
      if (inicio > 0) registros.add(const SizedBox(height: 16));
      registros.add(
        Row(
          children: [
            for (var i = inicio; i < inicio + colunas; i++) ...[
              if (i > inicio) const SizedBox(width: 16),
              Expanded(
                child: i < nomes.length
                    ? AspectRatio(
                        aspectRatio: formato,
                        child: _CartaoCategoria(nome: nomes[i], capa: catalogo.capaDa(nomes[i]), grande: grande),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: registros);
  }
}

/// Card de uma categoria com a foto de um produto dela.
class _CartaoCategoria extends StatelessWidget {
  const _CartaoCategoria({required this.nome, required this.capa, required this.grande});

  final String nome;
  final String capa;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TemaNice.grafite,
      borderRadius: BorderRadius.circular(TemaNice.raio),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => abrirCategoria(context, nome),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (capa.isNotEmpty)
              ImagemRede(url: capa, ajuste: BoxFit.cover)
            else
              Center(child: Icon(_iconesCategorias[nome], size: 56, color: TemaNice.vermelhoVivo)),
            const DecoratedBox(decoration: BoxDecoration(gradient: TemaNice.sombraInferior)),
            Positioned(
              left: grande ? 32 : 16,
              right: 16,
              bottom: grande ? 28 : 14,
              child: Text(
                nome.toUpperCase(),
                textAlign: grande ? TextAlign.start : TextAlign.center,
                style: TemaNice.rotuloCategoria(grande: grande),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
