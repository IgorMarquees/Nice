import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../theme/nice_theme.dart';
import '../widgets/nice_logo.dart';
import '../widgets/primary_button.dart';
import '../widgets/social_button.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      body: _AuthBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 28),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const NiceLogo(light: true),
                  const SizedBox(height: 82),
                  Text('Bem-vindo de volta', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  const Text('Acesse sua conta para continuar'),
                  const SizedBox(height: 48),
                  const Row(
                    children: [
                      SocialButton(label: 'Google', icon: Icons.g_mobiledata),
                      SizedBox(width: 18),
                      SocialButton(label: 'Apple', icon: Icons.apple),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OU', style: TextStyle(color: Colors.black.withValues(alpha: 0.55))),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'Email:'),
                    validator: (value) => value != null && value.contains('@') ? null : 'Informe um email valido',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'Senha:'),
                    validator: (value) => value != null && value.length >= 6 ? null : 'Minimo de 6 caracteres',
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Esqueceu senha?', style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ),
                  PrimaryButton(
                    label: 'Entrar',
                    loading: auth.loading,
                    onPressed: _submit,
                  ),
                  if (auth.error != null) ...[
                    const SizedBox(height: 12),
                    Text(auth.error!, style: const TextStyle(color: NiceTheme.red)),
                  ],
                  const SizedBox(height: 22),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignUpScreen()));
                    },
                    child: const Text.rich(
                      TextSpan(
                        text: 'Criar uma conta? ',
                        style: TextStyle(color: Colors.black87, fontSize: 12),
                        children: [
                          TextSpan(text: 'Sign up', style: TextStyle(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthController>().signIn(
          _emailController.text,
          _passwordController.text,
        );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111111), Colors.white, Color(0xFFD00000)],
          stops: [0, 0.48, 1],
        ),
      ),
      child: child,
    );
  }
}