import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controladores/controlador_enderecos.dart';
import '../../controladores/controlador_autenticacao.dart';
import '../../controladores/controlador_pedidos.dart';
import '../../dados/usuario.dart';
import '../../dados/pedido.dart';
import '../../nucleo/tema.dart';
import '../../nucleo/navegacao.dart';
import '../componentes/formulario_endereco.dart';
import '../componentes/cartao_pedido.dart';
import '../componentes/responsivo.dart';
import '../componentes/politica_trocas.dart';
import '../componentes/redes_sociais.dart';
import '../componentes/estados_tela.dart';

enum _Secao { pedidos, enderecos, trocas }

class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  @override
  State<TelaPerfil> createState() => _TelaPerfilEstado();
}

class _TelaPerfilEstado extends State<TelaPerfil> {
  final _chaves = {for (final s in _Secao.values) s: GlobalKey()};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final idUsuario = context.read<ControladorAutenticacao>().usuario?.id;
      if (idUsuario != null) context.read<ControladorPedidos>().carregarMeus(idUsuario);
    });
  }

  void _rolarAte(_Secao secao) {
    final alvo = _chaves[secao]!.currentContext;
    if (alvo == null) return;
    Scrollable.ensureVisible(alvo, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final autenticacao = context.watch<ControladorAutenticacao>();
    final pedidos = context.watch<ControladorPedidos>();
    final enderecos = context.watch<ControladorEnderecos>();
    final texto = Theme.of(context).textTheme;
    final usuario = autenticacao.usuario;
    if (usuario == null) return const Carregando();
    final computador = context.ehComputador;

    final secoes = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CartaoSecao(
          key: _chaves[_Secao.pedidos],
          icone: Icons.receipt_long_outlined,
          titulo: 'Meus pedidos',
          acaoDireita: pedidos.pedidos.isEmpty ? null : Text('${pedidos.pedidos.length}', style: texto.titleSmall),
          conteudo: _ListaPedidos(controlador: pedidos),
        ),
        const SizedBox(height: 20),
        _CartaoSecao(
          key: _chaves[_Secao.enderecos],
          icone: Icons.location_on_outlined,
          titulo: 'Meus endereços',
          acaoDireita: TextButton.icon(
            onPressed: () => abrirDialogoEndereco(context, destinatario: usuario.nome),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar'),
          ),
          conteudo: _ListaEnderecos(controlador: enderecos, destinatario: usuario.nome),
        ),
        const SizedBox(height: 20),
        _CartaoSecao(
          key: _chaves[_Secao.trocas],
          icone: Icons.autorenew,
          titulo: 'Trocas e devoluções',
          conteudo: const PoliticaTrocas(),
        ),
      ],
    );

    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Minha conta', style: TemaNice.sobretituloSecao(grande: computador)),
        const SizedBox(height: 6),
        Text('OLÁ, ${usuario.nome.split(' ').first.toUpperCase()}', style: TemaNice.tituloSecao(grande: computador)),
      ],
    );

    if (computador) {
      return ConteudoCentralizado(
        conteudo: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titulo,
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 300,
                    child: _MenuLateral(
                      usuario: usuario,
                      qtdPedidos: pedidos.pedidos.length,
                      aoNavegar: _rolarAte,
                      aoSair: autenticacao.sair,
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(child: secoes),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return ConteudoCentralizado(
      conteudo: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            titulo,
            const SizedBox(height: 20),
            _CartaoUsuario(usuario: usuario),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in _menu)
                  ActionChip(
                    avatar: Icon(item.icone, size: 18, color: TemaNice.vermelho),
                    label: Text(item.rotulo),
                    onPressed: () => _rolarAte(item.secao),
                  ),
              ],
            ),
            if (usuario.ehAdmin) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/admin'),
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('PAINEL ADMINISTRATIVO'),
              ),
            ],
            const SizedBox(height: 24),
            secoes,
            const SizedBox(height: 24),
            const _SigaNice(),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: autenticacao.sair, icon: const Icon(Icons.logout), label: const Text('SAIR')),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ItemMenu {
  const _ItemMenu(this.secao, this.icone, this.rotulo);
  final _Secao secao;
  final IconData icone;
  final String rotulo;
}

const _menu = [
  _ItemMenu(_Secao.pedidos, Icons.receipt_long_outlined, 'Meus pedidos'),
  _ItemMenu(_Secao.enderecos, Icons.location_on_outlined, 'Meus endereços'),
  _ItemMenu(_Secao.trocas, Icons.autorenew, 'Trocas e devoluções'),
];

class _CartaoSecao extends StatelessWidget {
  const _CartaoSecao({super.key, required this.icone, required this.titulo, required this.conteudo, this.acaoDireita});

  final IconData icone;
  final String titulo;
  final Widget conteudo;
  final Widget? acaoDireita;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Material(
      color: TemaNice.branco,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TemaNice.raio),
        side: const BorderSide(color: TemaNice.cinzaSuave, width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.ehCelular ? 18 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icone, color: TemaNice.vermelho),
                const SizedBox(width: 10),
                Expanded(child: Text(titulo.toUpperCase(), style: texto.titleLarge)),
                ?acaoDireita,
              ],
            ),
            const SizedBox(height: 18),
            conteudo,
          ],
        ),
      ),
    );
  }
}

class _CartaoUsuario extends StatelessWidget {
  const _CartaoUsuario({required this.usuario});

  final Usuario usuario;

  String get _iniciais {
    final partes = usuario.nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return 'N';
    return (partes.first[0] + (partes.length > 1 ? partes.last[0] : '')).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      color: TemaNice.preto,
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: TemaNice.vermelhoVivo,
            child: Text(_iniciais, style: texto.titleMedium?.copyWith(color: TemaNice.branco)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usuario.nome,
                  style: texto.titleLarge?.copyWith(color: TemaNice.branco),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  usuario.email,
                  style: texto.bodySmall?.copyWith(color: TemaNice.cinzaMedio),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (usuario.ehAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: TemaNice.vermelhoVivo,
              child: Text('ADMIN', style: TemaNice.selo()),
            ),
        ],
      ),
    );
  }
}

class _MenuLateral extends StatelessWidget {
  const _MenuLateral({required this.usuario, required this.qtdPedidos, required this.aoNavegar, required this.aoSair});

  final Usuario usuario;
  final int qtdPedidos;
  final ValueChanged<_Secao> aoNavegar;
  final VoidCallback aoSair;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CartaoUsuario(usuario: usuario),
        Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: TemaNice.cinzaSuave, width: 1.5),
              right: BorderSide(color: TemaNice.cinzaSuave, width: 1.5),
              bottom: BorderSide(color: TemaNice.cinzaSuave, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              for (final item in _menu)
                ListTile(
                  leading: Icon(item.icone, color: TemaNice.vermelho),
                  title: Text(item.rotulo, style: texto.titleSmall),
                  trailing: item.secao == _Secao.pedidos && qtdPedidos > 0
                      ? Text('$qtdPedidos', style: texto.bodySmall)
                      : const Icon(Icons.chevron_right, size: 20),
                  onTap: () => aoNavegar(item.secao),
                ),
            ],
          ),
        ),
        if (usuario.ehAdmin) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.go('/admin'),
            icon: const Icon(Icons.admin_panel_settings_outlined),
            label: const Text('PAINEL ADMINISTRATIVO'),
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: aoSair, icon: const Icon(Icons.logout), label: const Text('SAIR')),
        const SizedBox(height: 28),
        const _SigaNice(),
      ],
    );
  }
}

class _SigaNice extends StatelessWidget {
  const _SigaNice();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SIGA A NICE', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        const RedesSociais(),
      ],
    );
  }
}

class _ListaPedidos extends StatelessWidget {
  const _ListaPedidos({required this.controlador});

  final ControladorPedidos controlador;

  @override
  Widget build(BuildContext context) {
    if (controlador.carregando) return const Carregando();
    if (controlador.erro != null) return MensagemFormulario(texto: controlador.erro!);
    if (controlador.pedidos.isEmpty) {
      return _BlocoVazio(
        icone: Icons.shopping_bag_outlined,
        mensagem: 'Você ainda não fez pedidos.',
        textoAcao: 'VER CATÁLOGO',
        aoAgir: () => context.go(caminhoCatalogo(irParaProdutos: true)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final pedido in controlador.pedidos) ...[CartaoPedido(pedido: pedido), const SizedBox(height: 12)],
      ],
    );
  }
}

/// Lista de endereços.
/// Aparece sempre para o cliente poder cadastrar antes da primeira compra.
class _ListaEnderecos extends StatelessWidget {
  const _ListaEnderecos({required this.controlador, required this.destinatario});

  final ControladorEnderecos controlador;
  final String destinatario;

  Future<void> _excluir(BuildContext context, EnderecoSalvo endereco) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir endereço'),
        content: Text('Deseja excluir "${endereco.titulo}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmado == true) await controlador.excluir(endereco);
  }

  @override
  Widget build(BuildContext context) {
    if (controlador.carregando && controlador.itens.isEmpty) return const LinearProgressIndicator();
    if (controlador.itens.isEmpty) {
      return _BlocoVazio(
        icone: Icons.add_location_alt_outlined,
        mensagem:
            controlador.erro ??
            'Nenhum endereço salvo. Cadastre um para preencher a entrega automaticamente na finalização da compra.',
        textoAcao: 'CADASTRAR ENDEREÇO',
        aoAgir: () => abrirDialogoEndereco(context, destinatario: destinatario),
      );
    }

    return LayoutBuilder(
      builder: (context, limites) {
        final colunas = limites.maxWidth >= 620 ? 2 : 1;
        final largura = (limites.maxWidth - (colunas - 1) * 12) / colunas;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final endereco in controlador.itens)
              SizedBox(
                width: largura,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
                  decoration: BoxDecoration(
                    color: TemaNice.cinzaClaro,
                    borderRadius: BorderRadius.circular(TemaNice.raio),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ResumoEndereco(endereco: endereco.endereco, titulo: endereco.titulo),
                      ),
                      IconButton(
                        tooltip: 'Editar',
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => abrirDialogoEndereco(context, inicial: endereco),
                      ),
                      IconButton(
                        tooltip: 'Excluir',
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _excluir(context, endereco),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BlocoVazio extends StatelessWidget {
  const _BlocoVazio({required this.icone, required this.mensagem, required this.textoAcao, required this.aoAgir});

  final IconData icone;
  final String mensagem;
  final String textoAcao;
  final VoidCallback aoAgir;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: TemaNice.cinzaClaro, borderRadius: BorderRadius.circular(TemaNice.raio)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, color: TemaNice.cinzaMedio),
              const SizedBox(width: 12),
              Expanded(child: Text(mensagem, style: Theme.of(context).textTheme.bodyMedium)),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: aoAgir, child: Text(textoAcao)),
        ],
      ),
    );
  }
}
