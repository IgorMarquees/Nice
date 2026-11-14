import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'router/app_router.dart';
import 'theme/nice_theme.dart';

class NiceApp extends StatefulWidget {
  const NiceApp({super.key});

  @override
  State<NiceApp> createState() => _NiceAppState();
}

class _NiceAppState extends State<NiceApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildRouter(context.read<AuthController>());
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'NICE Streetwear',
      theme: NiceTheme.light(),
      routerConfig: _router,
    );
  }
}
