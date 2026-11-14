import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../theme/nice_theme.dart';
import '../widgets/auth_layout.dart';
import '../widgets/primary_button.dart';
import '../widgets/social_auth_buttons.dart';
import '../widgets/state_views.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.from});

  final String? from;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthController>().clearMessages();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthController>().signUp(_name.text, _email.text, _password.text);
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
            Text('JUNTE-SE À NICE', style: text.headlineMedium),
            const SizedBox(height: 8),
            Text('Entre para o universo do streetwear japonês', style: text.bodyMedium),
            const SizedBox(height: 28),
            const SocialAuthButtons(),
            TextFormField(
              controller: _name,
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
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(hintText: 'Senha'),
              validator: (v) => v != null && v.length >= 6 ? null : 'Mínimo de 6 caracteres',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(hintText: 'Confirmar senha'),
              validator: (v) => v == _password.text ? null : 'As senhas precisam coincidir',
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: 'CRIAR CONTA', loading: auth.loading, onPressed: _submit),
            if (auth.error != null) InlineMessage(text: auth.error!),
            if (auth.info != null) InlineMessage(text: auth.info!, isError: false),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/login$fromQuery'),
              child: const Text('Já tem conta? Entrar'),
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
