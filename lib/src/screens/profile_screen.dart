import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../theme/nice_theme.dart';
import '../widgets/nice_logo.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: NiceLogo(compact: true)),
            const SizedBox(height: 40),
            Text('Perfil', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: NiceTheme.softGray,
              leading: const CircleAvatar(backgroundColor: NiceTheme.red, child: Icon(Icons.person, color: Colors.white)),
              title: Text(auth.user?.name ?? 'Cliente NICE'),
              subtitle: Text(auth.user?.email ?? ''),
            ),
            const SizedBox(height: 24),
            const Text(
              'Perfil, carrinho, favoritos e pedidos conectados ao Firebase.',
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
                onPressed: auth.signOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
