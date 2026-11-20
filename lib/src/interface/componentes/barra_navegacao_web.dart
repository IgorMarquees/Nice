import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controladores/controlador_autenticacao.dart';
import '../../controladores/controlador_carrinho.dart';
import '../../nucleo/tema.dart';
import '../../nucleo/navegacao.dart';
import 'logo_nice.dart';
import 'responsivo.dart';

class DestinoMenu {
  const DestinoMenu(this.rotulo, this.caminho);
  final String rotulo;
  final String caminho;
}

const destinosWeb = [
  DestinoMenu('Home', '/'),
  DestinoMenu('Novidades', '/novidades'),
  DestinoMenu('Catálogo', '/catalogo'),
  DestinoMenu('Sobre nós', '/sobre'),
];

bool _estaAtivo(String local, String caminho) =>
    caminho == '/' ? local == '/' : local.startsWith(caminho);

/// Toda busca abre o catálogo já rolado até os produtos.
void _buscar(BuildContext context, String valor) => context.buscarNoCatalogo(valor);

class BarraNavegacaoWeb extends StatelessWidget {
  const BarraNavegacaoWeb({super.key, required this.local});

  final String local;

  /// Abaixo desta largura o menu vira gaveta.
  static const _larguraMenu = 980.0;
  /// A partir desta largura aparece o campo de busca.
  static const _larguraCompleta = 1240.0;

  @override
  Widget build(BuildContext context) {
    final autenticacao = context.watch<ControladorAutenticacao>();
    final qtdCarrinho = context.watch<ControladorCarrinho>().qtdItens;
    final largura = context.larguraTela;
    final largo = largura >= _larguraMenu;
    final completo = largura >= _larguraCompleta;

    return Material(
      color: TemaNice.branco,
      elevation: 0,
      child: Container(
        height: 72,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: TemaNice.cinzaSuave)),
        ),
        child: ConteudoCentralizado(
          conteudo: Row(
            children: [
              InkWell(
                onTap: () => context.go('/'),
                child: const LogoNice(pequena: true),
              ),
              if (largo) ...[
                SizedBox(width: completo ? 40 : 24),
                for (final item in destinosWeb)
                  _LinkMenu(item: item, ativo: _estaAtivo(local, item.caminho)),
                if (completo) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: _CampoBusca(aoEnviar: (v) => _buscar(context, v)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  const Spacer(),
                  IconButton(
                    tooltip: 'Buscar',
                    onPressed: () => context.buscarNoCatalogo(''),
                    icon: const Icon(Icons.search),
                  ),
                ],
              ] else
                const Spacer(),
              IconButton(
                tooltip: 'Carrinho',
                onPressed: () => context.go('/carrinho'),
                icon: Badge(
                  isLabelVisible: qtdCarrinho > 0,
                  label: Text('$qtdCarrinho'),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
              ),
              if (largo) ..._acoesConta(context, autenticacao, mostrarApelido: completo) else
                Builder(
                  builder: (context) => IconButton(
                    tooltip: 'Menu',
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                    icon: const Icon(Icons.menu),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _acoesConta(BuildContext context, ControladorAutenticacao autenticacao, {required bool mostrarApelido}) {
    if (!autenticacao.estaLogado) {
      return [
        IconButton(
          tooltip: 'Entrar',
          onPressed: () => context.go('/login'),
          icon: const Icon(Icons.person_outline),
        ),
      ];
    }
    return [
      if (autenticacao.ehAdmin)
        mostrarApelido
            ? TextButton.icon(
                onPressed: () => context.go('/admin'),
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                label: const Text('Admin'),
              )
            : IconButton(
                tooltip: 'Painel admin',
                color: TemaNice.vermelho,
                onPressed: () => context.go('/admin'),
                icon: const Icon(Icons.admin_panel_settings_outlined),
              ),
      IconButton(
        tooltip: 'Minha conta',
        onPressed: () => context.go('/perfil'),
        icon: const Icon(Icons.person),
      ),
    ];
  }
}

class _LinkMenu extends StatelessWidget {
  const _LinkMenu({required this.item, required this.ativo});

  final DestinoMenu item;
  final bool ativo;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => context.go(item.caminho),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: context.larguraTela >= BarraNavegacaoWeb._larguraCompleta ? 14 : 10),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: ativo ? TemaNice.vermelho : TemaNice.transparente, width: 2),
          ),
        ),
        child: Text(item.rotulo, style: texto.labelLarge),
      ),
    );
  }
}

class _CampoBusca extends StatelessWidget {
  const _CampoBusca({required this.aoEnviar});

  final ValueChanged<String> aoEnviar;

  @override
  Widget build(BuildContext context) {
    return TextField(
      textInputAction: TextInputAction.search,
      onSubmitted: aoEnviar,
      decoration: const InputDecoration(
        hintText: 'Encontre seu drip...',
        isDense: true,
        prefixIcon: Icon(Icons.search, color: TemaNice.vermelho),
      ),
    );
  }
}

class MenuLateralWeb extends StatelessWidget {
  const MenuLateralWeb({super.key, required this.local});

  final String local;

  @override
  Widget build(BuildContext context) {
    final autenticacao = context.watch<ControladorAutenticacao>();

    void abrir(String caminho) {
      Navigator.of(context).pop();
      context.go(caminho);
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Align(alignment: Alignment.centerLeft, child: LogoNice(pequena: true)),
            const SizedBox(height: 20),
            _CampoBusca(
              aoEnviar: (v) {
                Navigator.of(context).pop();
                _buscar(context, v);
              },
            ),
            const SizedBox(height: 12),
            for (final item in destinosWeb)
              ListTile(
                selected: _estaAtivo(local, item.caminho),
                selectedColor: TemaNice.vermelho,
                title: Text(item.rotulo),
                onTap: () => abrir(item.caminho),
              ),
            const Divider(),
            if (!autenticacao.estaLogado)
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Entrar'),
                onTap: () => abrir('/login'),
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Minha conta'),
                onTap: () => abrir('/perfil'),
              ),
              if (autenticacao.ehAdmin)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Painel admin'),
                  onTap: () => abrir('/admin'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
