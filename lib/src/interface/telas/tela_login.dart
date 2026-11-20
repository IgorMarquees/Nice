import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controladores/controlador_autenticacao.dart';
import '../../nucleo/tema.dart';
import '../componentes/layout_autenticacao.dart';
import '../componentes/botao_principal.dart';
import '../componentes/botoes_login_social.dart';
import '../componentes/estados_tela.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key, this.origem});

  final String? origem;

  @override
  State<TelaLogin> createState() => _TelaLoginEstado();
}

class _TelaLoginEstado extends State<TelaLogin> {
  final _chaveFormulario = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _ocultar = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ControladorAutenticacao>().limparMensagens();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _enviarFormulario() async {
    if (!_chaveFormulario.currentState!.validate()) return;
    await context.read<ControladorAutenticacao>().entrar(_email.text, _senha.text);
  }

  Future<void> _esqueciSenha() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoRecuperarSenha(emailInicial: _email.text),
    );
    if (email == null || !mounted) return;
    await context.read<ControladorAutenticacao>().enviarRecuperacaoSenha(email);
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
            Text('BEM-VINDO DE VOLTA', style: texto.headlineMedium),
            const SizedBox(height: 8),
            Text('Acesse sua conta para continuar', style: texto.bodyMedium),
            const SizedBox(height: 28),
            const BotoesLoginSocial(),
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
              obscureText: _ocultar,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _enviarFormulario(),
              decoration: InputDecoration(
                hintText: 'Senha',
                suffixIcon: IconButton(
                  icon: Icon(_ocultar ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _ocultar = !_ocultar),
                ),
              ),
              validator: (v) => v != null && v.length >= 6 ? null : 'Mínimo de 6 caracteres',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _esqueciSenha, child: const Text('Esqueceu a senha?')),
            ),
            BotaoPrincipal(rotulo: 'ENTRAR', carregando: autenticacao.carregando, aoPressionar: _enviarFormulario),
            if (autenticacao.erro != null) MensagemFormulario(texto: autenticacao.erro!),
            if (autenticacao.aviso != null) MensagemFormulario(texto: autenticacao.aviso!, ehErro: false),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/cadastro$consultaOrigem'),
              child: const Text('Não tem conta? Cadastre-se'),
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

/// Diálogo de recuperar senha.
/// Ele mesmo cuida do campo de texto para não dar erro ao fechar.
class _DialogoRecuperarSenha extends StatefulWidget {
  const _DialogoRecuperarSenha({required this.emailInicial});

  final String emailInicial;

  @override
  State<_DialogoRecuperarSenha> createState() => _DialogoRecuperarSenhaEstado();
}

class _DialogoRecuperarSenhaEstado extends State<_DialogoRecuperarSenha> {
  late final _controlador = TextEditingController(text: widget.emailInicial);
  final _chaveFormulario = GlobalKey<FormState>();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _enviar() {
    if (!_chaveFormulario.currentState!.validate()) return;
    Navigator.pop(context, _controlador.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recuperar senha'),
      content: Form(
        key: _chaveFormulario,
        child: TextFormField(
          controller: _controlador,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'Seu e-mail'),
          validator: (v) => v != null && v.contains('@') ? null : 'Informe um e-mail válido',
          onFieldSubmitted: (_) => _enviar(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _enviar, child: const Text('Enviar link')),
      ],
    );
  }
}
