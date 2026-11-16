import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Aviso de "adicionado ao carrinho" com atalho para o carrinho.
///
/// No Flutter atual, SnackBar com `action` fica fixa por padrão
/// (`persist` = true); por isso `persist: false` + duração explícita.
/// O roteador é capturado antes, para o botão funcionar mesmo que a tela
/// de origem seja trocada enquanto o aviso está aberto.
void showAddedToCart(BuildContext context, String title) {
  final router = GoRouter.of(context);
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('$title adicionado ao carrinho'),
        duration: const Duration(seconds: 4),
        persist: false,
        action: SnackBarAction(
          label: 'VER CARRINHO',
          onPressed: () => router.go('/carrinho'),
        ),
      ),
    );
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), persist: false));
}
