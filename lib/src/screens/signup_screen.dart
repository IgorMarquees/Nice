import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../widgets/nice_logo.dart';
import '../widgets/primary_button.dart';
import '../widgets/social_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF151515), Colors.white, Color(0xFF222222)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 28),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const NiceLogo(light: true),
                  const SizedBox(height: 72),
                  Text('Junte-se a NICE', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 10),
                  const Text('Entre para o universo do\nstreetwear japones', textAlign: TextAlign.center),
                  const SizedBox(height: 48),
                  const Row(
                    children: [
                      SocialButton(label: 'Google', icon: Icons.g_mobiledata),
                      SizedBox(width: 18),
                      SocialButton(label: 'Apple', icon: Icons.apple),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.all(12), child: Text('OU')), Expanded(child: Divider())]),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(hintText: 'Nome:'),
                    validator: (value) => value != null && value.trim().length >= 2 ? null : 'Informe seu nome',
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'Confirmar senha:'),
                    validator: (value) => value == _passwordController.text ? null : 'As senhas precisam coincidir',
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(label: 'Juntar-se', loading: auth.loading, onPressed: _submit),
                  if (auth.error != null) ...[
                    const SizedBox(height: 12),
                    Text(auth.error!, style: const TextStyle(color: Colors.red)),
                  ],
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Criar uma conta? Sign up', style: TextStyle(color: Colors.black87, fontSize: 12)),
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
    final ok = await context.read<AuthController>().signUp(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );
    if (ok && mounted) Navigator.of(context).pop();
  }
}