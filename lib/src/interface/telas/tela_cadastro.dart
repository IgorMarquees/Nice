// Tela de cadastro.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controladores/controlador_autenticacao.dart';
import '../../nucleo/tema.dart';
import '../componentes/layout_autenticacao.dart';
import '../componentes/botao_principal.dart';
import '../componentes/botoes_login_social.dart';
import '../componentes/estados_tela.dart';

/// Cria uma conta nova com nome email e senha.
class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key, this.origem});

  /// Página para voltar depois do cadastro.
  final String? origem;

  @override
  State<TelaCadastro> createState() => _TelaCadastroEstado();
}

class _TelaCadastroEstado extends State<TelaCadastro> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirmar = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ControladorAutenticacao>().limparMensagens();
    });
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  /// Valida o formulário e cria a conta.
  Future<void> _enviarFormulario() async {
    if (!_chaveFormulario.currentState!.validate()) return;
    await context.read<ControladorAutenticacao>().cadastrar(_nome.text, _email.text, _senha.text);
  }

  @override
  Widget build(BuildContext context) {
    final autenticacao = context.watch<ControladorAutenticacao>();
    final texto = Theme.of(context).textTheme;
    final consultaOrigem = widget.origem == null ? '' : '?from=${Uri.encodeComponent(widget.origem!)}';

    return LayoutAutenticacao(
      conteudo: Form(
        key: _chaveFormulario,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('JUNTE-SE À NICE', style: texto.headlineMedium),
            const SizedBox(height: 8),
            Text('Entre para o universo do streetwear japonês', style: texto.bodyMedium),
            const SizedBox(height: 28),
            const BotoesLoginSocial(),
            TextFormField(
              controller: _nome,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(hintText: 'Nome'),
              validator: (v) => v != null && v.trim().length >= 2 ? null : 'Informe seu nome',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(hintText: 'E-mail'),
              validator: (v) => v != null && v.contains('@') ? null : 'Informe um e-mail válido',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _senha,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(hintText: 'Senha'),
              validator: (v) => v != null && v.length >= 6 ? null : 'Mínimo de 6 caracteres',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmar,
              obscureText: true,
              onFieldSubmitted: (_) => _enviarFormulario(),
              decoration: const InputDecoration(hintText: 'Confirmar senha'),
              validator: (v) => v == _senha.text ? null : 'As senhas precisam coincidir',
            ),
            const SizedBox(height: 20),
            BotaoPrincipal(rotulo: 'CRIAR CONTA', carregando: autenticacao.carregando, aoPressionar: _enviarFormulario),
            if (autenticacao.erro != null) MensagemFormulario(texto: autenticacao.erro!),
            if (autenticacao.aviso != null) MensagemFormulario(texto: autenticacao.aviso!, ehErro: false),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/login$consultaOrigem'),
              child: const Text('Já tem conta? Entrar'),
            ),
            TextButton(
              onPressed: () => context.go('/'),
              style: TextButton.styleFrom(foregroundColor: TemaNice.cinzaTexto),
              child: const Text('Continuar como visitante'),
            ),
          ],
        ),
      ),
    );
  }
}
