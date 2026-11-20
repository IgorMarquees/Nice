// Detalhes de um usuário para o administrador.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../controladores/controlador_autenticacao.dart';
import '../../../controladores/controlador_usuarios.dart';
import '../../../dados/usuario.dart';
import '../../../nucleo/tema.dart';
import '../../../nucleo/avisos.dart';
import '../../../nucleo/formatadores.dart';
import '../../componentes/formulario_endereco.dart';
import '../../componentes/cartao_pedido.dart';
import '../../componentes/responsivo.dart';
import '../../componentes/estados_tela.dart';

/// Dados endereços pedidos e o botão de tornar ou remover admin.
class TelaDetalheUsuario extends StatefulWidget {
  const TelaDetalheUsuario({super.key, required this.idUsuario});

  final String idUsuario;

  @override
  State<TelaDetalheUsuario> createState() => _TelaDetalheUsuarioEstado();
}

class _TelaDetalheUsuarioEstado extends State<TelaDetalheUsuario> {
  DetalhesUsuario? _detalhes;
  bool _carregando = true;
  bool _trocandoPapel = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  /// Carrega perfil endereços e pedidos.
  Future<void> _carregar() async {
    final detalhes = await context.read<ControladorUsuarios>().detalhes(widget.idUsuario);
    if (!mounted) return;
    setState(() {
      _detalhes = detalhes;
      _carregando = false;
    });
  }

  /// Pede confirmação e troca o tipo de conta.
  Future<void> _trocarPapel(Usuario usuario) async {
    final tornarAdmin = !usuario.ehAdmin;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tornarAdmin ? 'Tornar administrador' : 'Remover administrador'),
        content: Text(
          tornarAdmin
              ? '${usuario.nome} poderá cadastrar produtos, ver estoque e gerenciar usuários. Continuar?'
              : '${usuario.nome} voltará a ser um cliente comum. Continuar?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _trocandoPapel = true);
    final papel = tornarAdmin ? PapelUsuario.admin : PapelUsuario.cliente;
    final erro = await context.read<ControladorUsuarios>().definirPapel(usuario, papel);
    if (!mounted) return;
    setState(() {
      _trocandoPapel = false;
      if (erro == null) _detalhes = _detalhes?.copiarCom(usuario: usuario.copiarCom(papel: papel));
    });
    mostrarMensagem(context, erro ?? (tornarAdmin ? 'Usuário agora é administrador.' : 'Usuário agora é cliente.'));
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Carregando();
    final detalhes = _detalhes;
    if (detalhes == null) {
      return EstadoVazio(
        icone: Icons.person_off_outlined,
        titulo: 'Usuário não encontrado',
        textoAcao: 'Voltar',
        aoAgir: () => context.go('/admin/usuarios'),
      );
    }

    final texto = Theme.of(context).textTheme;
    final usuario = detalhes.usuario;
    final ehVoce = context.watch<ControladorAutenticacao>().usuario?.id == usuario.id;

    return ConteudoCentralizado(
      larguraMaxima: 900,
      conteudo: Padding(
        padding: EdgeInsets.symmetric(vertical: context.ehComputador ? 48 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('PAINEL ADMIN / USUÁRIOS', style: texto.labelMedium),
            const SizedBox(height: 4),
            Text(usuario.nome.toUpperCase(), style: texto.headlineLarge),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TemaNice.cinzaClaro,
                borderRadius: BorderRadius.circular(TemaNice.raio),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(usuario.email, style: texto.titleSmall),
                      Text(
                        'Perfil: ${usuario.ehAdmin ? 'Administrador' : 'Cliente'}'
                        '${usuario.criadoEm == null ? '' : ' · cadastro em ${formatarData(usuario.criadoEm)}'}',
                        style: texto.bodySmall,
                      ),
                    ],
                  ),
                  if (!ehVoce)
                    FilledButton.icon(
                      onPressed: _trocandoPapel ? null : () => _trocarPapel(usuario),
                      icon: Icon(usuario.ehAdmin ? Icons.remove_moderator_outlined : Icons.add_moderator_outlined),
                      label: Text(usuario.ehAdmin ? 'REMOVER ADMIN' : 'TORNAR ADMIN'),
                    )
                  else
                    Text('Esta é a sua conta', style: texto.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('ENDEREÇOS CADASTRADOS', style: texto.headlineSmall),
            const SizedBox(height: 12),
            if (detalhes.enderecos.isEmpty)
              Text('Nenhum endereço salvo.', style: texto.bodySmall)
            else
              for (final endereco in detalhes.enderecos) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(TemaNice.raio),
                    border: Border.all(color: TemaNice.cinzaSuave, width: 1.5),
                  ),
                  child: ResumoEndereco(endereco: endereco.endereco, titulo: endereco.titulo),
                ),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 32),
            Text('HISTÓRICO DE PEDIDOS (${detalhes.pedidos.length})', style: texto.headlineSmall),
            const SizedBox(height: 12),
            if (detalhes.pedidos.isEmpty)
              Text('Nenhum pedido realizado.', style: texto.bodySmall)
            else
              for (final pedido in detalhes.pedidos) ...[
                CartaoPedido(pedido: pedido),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
