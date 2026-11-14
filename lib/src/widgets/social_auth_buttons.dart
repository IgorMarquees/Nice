import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../controllers/auth_controller.dart';

/// Google no Android e Web; Apple somente no iOS.
class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final text = Theme.of(context).textTheme;

    final buttons = <Widget>[
      if (AppConfig.showGoogleLogin)
        _SocialButton(
          label: 'Continuar com Google',
          icon: Icons.g_mobiledata,
          onPressed: auth.loading ? null : auth.signInWithGoogle,
        ),
      if (AppConfig.showAppleLogin)
        _SocialButton(
          label: 'Continuar com Apple',
          icon: Icons.apple,
          onPressed: auth.loading ? null : auth.signInWithApple,
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        ...buttons,
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('OU', style: text.labelSmall),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 28),
          label: Text(label),
        ),
      ),
    );
  }
}
