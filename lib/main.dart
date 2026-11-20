import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/aplicativo.dart';
import 'src/nucleo/configuracao.dart';
import 'src/controladores/controlador_enderecos.dart';
import 'src/controladores/controlador_admin.dart';
import 'src/controladores/controlador_autenticacao.dart';
import 'src/controladores/controlador_carrinho.dart';
import 'src/controladores/controlador_catalogo.dart';
import 'src/controladores/controlador_pedidos.dart';
import 'src/controladores/controlador_usuarios.dart';
import 'src/dados/repositorio_enderecos.dart';
import 'src/dados/repositorio_autenticacao.dart';
import 'src/dados/repositorio_categorias.dart';
import 'src/dados/repositorio_carrinho.dart';
import 'src/dados/repositorio_vitrine_reserva.dart';
import 'src/dados/repositorio_pedidos.dart';
import 'src/dados/repositorio_produtos.dart';
import 'src/dados/repositorio_fotos.dart';
import 'src/dados/repositorio_usuarios.dart';
import 'src/nucleo/tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Na web os endereços ficam limpos como /produto/123 em vez de /#/produto/123.
  usePathUrlStrategy();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: TemaNice.transparente,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  if (!Configuracao.supabaseConfigurado) {
    debugPrint('⚠️ Supabase não configurado: use --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...');
  }
  await Supabase.initialize(
    url: Configuracao.urlSupabase,
    publishableKey: Configuracao.chaveSupabase,
  );
  // Conexão única com o Supabase usada por todos os repositórios.
  final conexao = Supabase.instance.client;

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => RepositorioAutenticacao(conexao)),
        Provider(create: (_) => RepositorioProdutos(conexao)),
        Provider(create: (_) => RepositorioVitrineReserva()),
        Provider(create: (_) => RepositorioCarrinho(conexao)),
        Provider(create: (_) => RepositorioPedidos(conexao)),
        Provider(create: (_) => RepositorioFotos(conexao)),
        Provider(create: (_) => RepositorioEnderecos(conexao)),
        Provider(create: (_) => RepositorioUsuarios(conexao)),
        Provider(create: (_) => RepositorioCategorias(conexao)),
        ChangeNotifierProvider(
          create: (context) => ControladorAutenticacao(context.read<RepositorioAutenticacao>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ControladorCatalogo(
            context.read<RepositorioProdutos>(),
            context.read<RepositorioVitrineReserva>(),
            context.read<RepositorioCategorias>(),
          )..carregar(),
        ),
        ChangeNotifierProxyProvider<ControladorAutenticacao, ControladorCarrinho>(
          create: (context) => ControladorCarrinho(context.read<RepositorioCarrinho>()),
          update: (_, autenticacao, carrinho) => carrinho!..vincularUsuario(autenticacao.usuario?.id),
        ),
        ChangeNotifierProvider(
          create: (context) => ControladorPedidos(context.read<RepositorioPedidos>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ControladorAdmin(
            context.read<RepositorioProdutos>(),
            context.read<RepositorioFotos>(),
          ),
        ),
        ChangeNotifierProxyProvider<ControladorAutenticacao, ControladorEnderecos>(
          create: (context) => ControladorEnderecos(context.read<RepositorioEnderecos>()),
          update: (_, autenticacao, enderecos) => enderecos!..vincularUsuario(autenticacao.usuario?.id),
        ),
        ChangeNotifierProvider(
          create: (context) => ControladorUsuarios(
            context.read<RepositorioUsuarios>(),
            context.read<RepositorioEnderecos>(),
            context.read<RepositorioPedidos>(),
          ),
        ),
      ],
      child: const AplicativoNice(),
    ),
  );
}
