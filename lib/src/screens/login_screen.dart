import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../theme/nice_theme.dart';
import '../widgets/auth_layout.dart';
import '../widgets/primary_button.dart';
import '../widgets/social_auth_buttons.dart';
import '../widgets/state_views.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.from});

  /// Rota para onde voltar após o login (ex.: produto que o visitante abriu).
  final String? from;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthController>().clearMessages();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthController>().signIn(_email.text, _password.text);
    // Em caso de sucesso o roteador redireciona automaticamente.
  }

  /// O diálogo é dono do próprio TextEditingController: antes ele era
  /// descartado logo após o pop, enquanto o diálogo ainda animava a saída
  /// usando o campo, o que gerava o erro "_dependents.isEmpty".
  Future<void> _forgotPassword() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ResetPasswordDialog(initialEmail: _email.text),
    );
    if (email == null || !mounted) return;
    await context.read<AuthController>().sendPasswordReset(email);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final text = Theme.of(context).textTheme;
    final fromQuery = widget.from == null ? '' : '?from=${Uri.encodeComponent(widget.from!)}';

    return AuthLayout(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('BEM-VINDO DE VOLTA', style: text.headlineMedium),
            const SizedBox(height: 8),
            Text('Acesse sua conta para continuar', style: text.bodyMedium),
            const SizedBox(height: 28),
            const SocialAuthButtons(),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(hintText: 'E-mail'),
              validator: (v) => v != null && v.contains('@') ? null : 'Informe um e-mail válido',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Senha',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => v != null && v.length >= 6 ? null : 'Mínimo de 6 caracteres',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _forgotPassword, child: const Text('Esqueceu a senha?')),
            ),
            PrimaryButton(label: 'ENTRAR', loading: auth.loading, onPressed: _submit),
            if (auth.error != null) InlineMessage(text: auth.error!),
            if (auth.info != null) InlineMessage(text: auth.info!, isError: false),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/cadastro$fromQuery'),
              child: const Text('Não tem conta? Cadastre-se'),
            ),
            TextButton(
              onPressed: () => context.go('/'),
              style: TextButton.styleFrom(foregroundColor: NiceTheme.textGray),
              child: const Text('Continuar como visitante'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  late final _controller = TextEditingController(text: widget.initialEmail);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recuperar senha'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'Seu e-mail'),
          validator: (v) => v != null && v.contains('@') ? null : 'Informe um e-mail válido',
          onFieldSubmitted: (_) => _send(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _send, child: const Text('Enviar link')),
      ],
    );
  }
}
