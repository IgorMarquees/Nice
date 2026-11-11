import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 54),
          foregroundColor: Colors.black54,
          backgroundColor: Colors.white.withValues(alpha: 0.68),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.15)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login com $label reservado para integracao futura.')),
          );
        },
        icon: Icon(icon, color: Colors.black),
        label: FittedBox(child: Text(label)),
      ),
    );
  }
}
