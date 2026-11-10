import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/auth_controller.dart';
import 'screens/login_screen.dart';
import 'screens/shop_shell.dart';
import 'theme/nice_theme.dart';

class NiceApp extends StatelessWidget {
  const NiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NICE Streetwear',
      theme: NiceTheme.light(),
      home: Consumer<AuthController>(
        builder: (context, auth, _) {
          if (auth.isSignedIn) {
            return const ShopShell();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
