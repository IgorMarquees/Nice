import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Aviso de produto adicionado com o botão Ver carrinho.
/// O aviso some sozinho e o botão usa o roteador guardado antes para sempre funcionar.
void avisarAdicionadoAoCarrinho(BuildContext context, String titulo) {
  final roteador = GoRouter.of(context);
  final mensageiro = ScaffoldMessenger.of(context);
  mensageiro
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('$titulo adicionado ao carrinho'),
        duration: const Duration(seconds: 4),
        persist: false,
        action: SnackBarAction(
          label: 'VER CARRINHO',
          onPressed: () => roteador.go('/carrinho'),
        ),
      ),
    );
}

void mostrarMensagem(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensagem), persist: false));
}
