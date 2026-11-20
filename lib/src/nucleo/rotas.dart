import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../controladores/controlador_autenticacao.dart';
import '../interface/telas/tela_sobre.dart';
import '../interface/telas/admin/tela_painel_admin.dart';
import '../interface/telas/admin/tela_descontos.dart';
import '../interface/telas/admin/tela_formulario_produto.dart';
import '../interface/telas/admin/tela_produtos_admin.dart';
import '../interface/telas/admin/tela_detalhe_usuario.dart';
import '../interface/telas/admin/tela_usuarios.dart';
import '../interface/telas/tela_carrinho.dart';
import '../interface/telas/tela_catalogo.dart';
import '../interface/telas/tela_finalizar_compra.dart';
import '../interface/telas/tela_inicio.dart';
import '../interface/telas/tela_login.dart';
import '../interface/telas/moldura_celular.dart';
import '../interface/telas/tela_novidades.dart';
import '../interface/telas/tela_produto.dart';
import '../interface/telas/tela_perfil.dart';
import '../interface/telas/tela_cadastro.dart';
import '../interface/telas/pagina_rolavel.dart';
import '../interface/telas/tela_carregando.dart';
import '../interface/telas/moldura_web.dart';
import 'navegacao.dart';
import '../interface/componentes/estados_tela.dart';

const _soCliente = ['/carrinho', '/checkout', '/perfil'];

const _soAdmin = ['/admin'];

/// Cria o roteador.
/// Quem não tem permissão é levado ao login ou à Home.
/// A segurança de verdade fica nas regras do banco.
GoRouter criarRotas(ControladorAutenticacao autenticacao) {
  bool combina(String caminho, List<String> prefixos) => prefixos.any(caminho.startsWith);

  return GoRouter(
    refreshListenable: autenticacao,
    errorBuilder: (context, estado) => Scaffold(
      body: EstadoVazio(
        icone: Icons.search_off,
        titulo: 'Página não encontrada',
        textoAcao: 'Ir para a Home',
        aoAgir: () => context.go('/'),
      ),
    ),
    redirect: (context, estado) {
      final caminho = estado.matchedLocation;
      final protegida = combina(caminho, _soCliente) || combina(caminho, _soAdmin);
      final aqui = Uri.encodeComponent(estado.uri.toString());

      if (autenticacao.situacao == SituacaoLogin.carregando) {
        return protegida ? '/carregando?from=$aqui' : null;
      }
      if (caminho == '/carregando') return estado.uri.queryParameters['from'] ?? '/';

      if (protegida && !autenticacao.estaLogado) return '/login?from=$aqui';
      if (combina(caminho, _soAdmin) && !autenticacao.ehAdmin) return '/';
      if ((caminho == '/login' || caminho == '/cadastro') && autenticacao.estaLogado) {
        return estado.uri.queryParameters['from'] ?? '/';
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, estado, conteudo) => kIsWeb
            ? MolduraWeb(local: estado.uri.path, conteudo: conteudo)
            : MolduraCelular(local: estado.uri.path, conteudo: conteudo),
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
            path: '/produto/:id',
            builder: (_, estado) => PaginaRolavel(
              conteudo: TelaProduto(
                key: ValueKey(estado.pathParameters['id']),
                idProduto: estado.pathParameters['id']!,
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
            path: '/checkout',
            builder: (_, _) => const PaginaRolavel(conteudo: TelaFinalizarCompra()),
          ),
          GoRoute(
            path: '/perfil',
            builder: (_, _) => const PaginaRolavel(conteudo: TelaPerfil()),
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
            path: '/admin/descontos',
            builder: (_, _) => const PaginaRolavel(conteudo: TelaDescontos()),
          ),
          GoRoute(
            path: '/admin/usuarios',
            builder: (_, _) => const PaginaRolavel(conteudo: TelaUsuarios()),
          ),
          GoRoute(
            path: '/admin/usuarios/:id',
            builder: (_, estado) => PaginaRolavel(
              conteudo: TelaDetalheUsuario(
                key: ValueKey(estado.pathParameters['id']),
                idUsuario: estado.pathParameters['id']!,
              ),
            ),
          ),
          GoRoute(
            path: '/admin/produto/novo',
            builder: (_, _) => const PaginaRolavel(conteudo: TelaFormularioProduto()),
          ),
          GoRoute(
            path: '/admin/produto/:id',
            builder: (_, estado) => PaginaRolavel(
              conteudo: TelaFormularioProduto(
                key: ValueKey(estado.pathParameters['id']),
                idProduto: estado.pathParameters['id'],
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        builder: (_, estado) => TelaLogin(origem: estado.uri.queryParameters['from']),
      ),
      GoRoute(
        path: '/cadastro',
        builder: (_, estado) => TelaCadastro(origem: estado.uri.queryParameters['from']),
      ),
      GoRoute(path: '/carregando', builder: (_, _) => const TelaCarregando()),
    ],
  );
}
