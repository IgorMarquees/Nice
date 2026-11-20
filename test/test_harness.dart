// Estrutura dos testes.
// Monta o app sem internet com produtos e login falsos.

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:nice_store/src/controladores/controlador_enderecos.dart';
import 'package:nice_store/src/controladores/controlador_admin.dart';
import 'package:nice_store/src/controladores/controlador_autenticacao.dart';
import 'package:nice_store/src/controladores/controlador_carrinho.dart';
import 'package:nice_store/src/controladores/controlador_catalogo.dart';
import 'package:nice_store/src/controladores/controlador_pedidos.dart';
import 'package:nice_store/src/controladores/controlador_usuarios.dart';
import 'package:nice_store/src/dados/usuario.dart';
import 'package:nice_store/src/dados/produto.dart';
import 'package:nice_store/src/dados/repositorio_enderecos.dart';
import 'package:nice_store/src/dados/repositorio_autenticacao.dart';
import 'package:nice_store/src/dados/repositorio_carrinho.dart';
import 'package:nice_store/src/dados/repositorio_vitrine_reserva.dart';
import 'package:nice_store/src/dados/repositorio_pedidos.dart';
import 'package:nice_store/src/dados/repositorio_produtos.dart';
import 'package:nice_store/src/dados/repositorio_fotos.dart';
import 'package:nice_store/src/dados/repositorio_usuarios.dart';
import 'package:nice_store/src/nucleo/navegacao.dart';
import 'package:nice_store/src/interface/telas/tela_sobre.dart';
import 'package:nice_store/src/interface/telas/admin/tela_painel_admin.dart';
import 'package:nice_store/src/interface/telas/admin/tela_descontos.dart';
import 'package:nice_store/src/interface/telas/admin/tela_formulario_produto.dart';
import 'package:nice_store/src/interface/telas/admin/tela_produtos_admin.dart';
import 'package:nice_store/src/interface/telas/admin/tela_usuarios.dart';
import 'package:nice_store/src/interface/telas/tela_carrinho.dart';
import 'package:nice_store/src/interface/telas/tela_catalogo.dart';
import 'package:nice_store/src/interface/telas/tela_finalizar_compra.dart';
import 'package:nice_store/src/interface/telas/tela_inicio.dart';
import 'package:nice_store/src/interface/telas/tela_login.dart';
import 'package:nice_store/src/interface/telas/moldura_celular.dart';
import 'package:nice_store/src/interface/telas/tela_novidades.dart';
import 'package:nice_store/src/interface/telas/tela_produto.dart';
import 'package:nice_store/src/interface/telas/tela_perfil.dart';
import 'package:nice_store/src/interface/telas/tela_cadastro.dart';
import 'package:nice_store/src/interface/telas/pagina_rolavel.dart';
import 'package:nice_store/src/interface/telas/moldura_web.dart';

class ProdutosFalsos implements RepositorioVitrineReserva {
  @override
  Future<List<Produto>> buscarProdutos() async => produtosReserva;

  @override
  List<Produto> get produtosReserva => RepositorioVitrineReserva().produtosReserva;
}

class ProdutosOffline extends RepositorioProdutos {
  ProdutosOffline(super.conexao, [this.produtos = const []]);

  final List<Produto> produtos;

  @override
  Future<List<Produto>> buscarTodos() async => produtos;

  @override
  Future<Produto?> buscarPorId(String id) async => produtos.where((p) => p.id == id).firstOrNull;
}

class AutenticacaoOffline extends RepositorioAutenticacao {
  AutenticacaoOffline(super.conexao);

  @override
  Stream<AuthState> get mudancasLogin => const Stream.empty();
}

class ProvedoresTeste extends StatelessWidget {
  const ProvedoresTeste({super.key, required this.conteudo, this.usuario, this.produtos = const []});

  final Widget conteudo;

  final List<Produto> produtos;

  final Usuario? usuario;

  @override
  Widget build(BuildContext context) {
    final conexao = SupabaseClient(
      'http://127.0.0.1:9',
      'test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    return MultiProvider(
      providers: [
        Provider<RepositorioAutenticacao>(create: (_) => AutenticacaoOffline(conexao)),
        Provider<RepositorioProdutos>(create: (_) => ProdutosOffline(conexao, produtos)),
        Provider<RepositorioVitrineReserva>(create: (_) => ProdutosFalsos()),
        Provider(create: (_) => RepositorioCarrinho(conexao)),
        Provider(create: (_) => RepositorioPedidos(conexao)),
        Provider(create: (_) => RepositorioFotos(conexao)),
        Provider(create: (_) => RepositorioEnderecos(conexao)),
        Provider(create: (_) => RepositorioUsuarios(conexao)),
        ChangeNotifierProvider(
          create: (c) {
            final autenticacao = ControladorAutenticacao(c.read<RepositorioAutenticacao>());
            if (usuario != null) autenticacao.simularLogin(usuario!);
            return autenticacao;
          },
        ),
        ChangeNotifierProvider(
          create: (c) => ControladorCatalogo(c.read<RepositorioProdutos>(), c.read<RepositorioVitrineReserva>())..carregar(),
        ),
        ChangeNotifierProxyProvider<ControladorAutenticacao, ControladorCarrinho>(
          create: (c) => ControladorCarrinho(c.read<RepositorioCarrinho>()),
          update: (_, autenticacao, carrinho) => carrinho!..vincularUsuario(autenticacao.usuario?.id),
        ),
        ChangeNotifierProvider(create: (c) => ControladorPedidos(c.read<RepositorioPedidos>())),
        ChangeNotifierProvider(
          create: (c) => ControladorAdmin(c.read<RepositorioProdutos>(), c.read<RepositorioFotos>()),
        ),
        ChangeNotifierProxyProvider<ControladorAutenticacao, ControladorEnderecos>(
          create: (c) => ControladorEnderecos(c.read<RepositorioEnderecos>()),
          update: (_, autenticacao, enderecos) => enderecos!..vincularUsuario(autenticacao.usuario?.id),
        ),
        ChangeNotifierProvider(
          create: (c) =>
              ControladorUsuarios(c.read<RepositorioUsuarios>(), c.read<RepositorioEnderecos>(), c.read<RepositorioPedidos>()),
        ),
      ],
      child: conteudo,
    );
  }
}

GoRouter rotasTeste(String inicial, {required bool web}) => GoRouter(
  initialLocation: inicial,
  routes: [
    ShellRoute(
      builder: (context, estado, conteudo) =>
          web ? MolduraWeb(local: estado.uri.path, conteudo: conteudo) : MolduraCelular(local: estado.uri.path, conteudo: conteudo),
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const PaginaRolavel(conteudo: TelaInicio()),
        ),
        GoRoute(
          path: '/novidades',
          builder: (_, _) => const PaginaRolavel(conteudo: TelaNovidades()),
        ),
        GoRoute(
          path: '/catalogo',
          builder: (_, estado) => PaginaRolavel(
            conteudo: TelaCatalogo(
              key: ValueKey(estado.uri.toString()),
              categoriaInicial: estado.uri.queryParameters['categoria'],
              buscaInicial: estado.uri.queryParameters['busca'],
              rolarAteProdutos: estado.uri.queryParameters['secao'] == secaoProdutosCatalogo,
            ),
          ),
        ),
        GoRoute(
          path: '/sobre',
          builder: (_, _) => const PaginaRolavel(conteudo: TelaSobre()),
        ),
        GoRoute(
          path: '/carrinho',
          builder: (_, _) => const PaginaRolavel(conteudo: TelaCarrinho()),
        ),
        GoRoute(
          path: '/produto/:id',
          builder: (_, estado) => PaginaRolavel(conteudo: TelaProduto(idProduto: estado.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/admin',
          builder: (_, _) => const PaginaRolavel(conteudo: TelaPainelAdmin()),
        ),
        GoRoute(
          path: '/admin/produtos',
          builder: (_, _) => const PaginaRolavel(conteudo: TelaProdutosAdmin()),
        ),
        GoRoute(
          path: '/admin/usuarios',
          builder: (_, _) => const PaginaRolavel(conteudo: TelaUsuarios()),
        ),
        GoRoute(
          path: '/admin/produto/novo',
          builder: (_, _) => const PaginaRolavel(conteudo: TelaFormularioProduto()),
        ),
        GoRoute(
          path: '/admin/descontos',
          builder: (_, _) => const PaginaRolavel(conteudo: TelaDescontos()),
        ),
        GoRoute(
          path: '/checkout',
          builder: (_, _) => const PaginaRolavel(conteudo: TelaFinalizarCompra()),
        ),
        GoRoute(
          path: '/perfil',
          builder: (_, _) => const PaginaRolavel(conteudo: TelaPerfil()),
        ),
      ],
    ),
    GoRoute(path: '/login', builder: (_, _) => const TelaLogin()),
    GoRoute(path: '/cadastro', builder: (_, _) => const TelaCadastro()),
  ],
);
