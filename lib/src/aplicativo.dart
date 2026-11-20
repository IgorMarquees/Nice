import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'controladores/controlador_autenticacao.dart';
import 'nucleo/rotas.dart';
import 'nucleo/tema.dart';

class AplicativoNice extends StatefulWidget {
  const AplicativoNice({super.key});

  @override
  State<AplicativoNice> createState() => _AplicativoNiceEstado();
}

class _AplicativoNiceEstado extends State<AplicativoNice> {
  /// O roteador é criado uma vez só e reaproveitado em todo o app.
  late final GoRouter _roteador;

  @override
  void initState() {
    super.initState();
    _roteador = criarRotas(context.read<ControladorAutenticacao>());
  }

  @override
  void dispose() {
    _roteador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'NICE Streetwear',
      theme: TemaNice.claro(),
      routerConfig: _roteador,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
