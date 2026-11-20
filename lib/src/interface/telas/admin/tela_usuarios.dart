// Lista de usuários para o administrador.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../controladores/controlador_usuarios.dart';
import '../../../dados/usuario.dart';
import '../../../nucleo/tema.dart';
import '../../../nucleo/formatadores.dart';
import '../../componentes/responsivo.dart';
import '../../componentes/estados_tela.dart';

/// Mostra os usuários cadastrados com busca por nome ou email.
class TelaUsuarios extends StatefulWidget {
  const TelaUsuarios({super.key});

  @override
  State<TelaUsuarios> createState() => _TelaUsuariosEstado();
}

class _TelaUsuariosEstado extends State<TelaUsuarios> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ControladorUsuarios>().carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuarios = context.watch<ControladorUsuarios>();
    final texto = Theme.of(context).textTheme;

    return ConteudoCentralizado(
      conteudo: Padding(
        padding: EdgeInsets.symmetric(vertical: context.ehComputador ? 48 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('PAINEL ADMIN', style: texto.labelMedium),
            const SizedBox(height: 4),
            Text('USUÁRIOS', style: texto.headlineLarge),
            const SizedBox(height: 20),
            TextField(
              onChanged: usuarios.pesquisar,
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou e-mail...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 20),
            if (usuarios.carregando)
              const Carregando()
            else if (usuarios.erro != null)
              MensagemFormulario(texto: usuarios.erro!)
            else if (usuarios.itens.isEmpty)
              const EstadoVazio(icone: Icons.people_outline, titulo: 'Nenhum usuário encontrado')
            else
              for (final usuario in usuarios.itens) ...[
                _ItemUsuario(usuario: usuario),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Linha de um usuário que abre os detalhes.
class _ItemUsuario extends StatelessWidget {
  const _ItemUsuario({required this.usuario});

  final Usuario usuario;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Material(
      color: TemaNice.branco,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TemaNice.raio),
        side: const BorderSide(color: TemaNice.cinzaSuave, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/admin/usuarios/${usuario.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: usuario.ehAdmin ? TemaNice.vermelho : TemaNice.cinzaSuave,
                child: Icon(
                  usuario.ehAdmin ? Icons.admin_panel_settings_outlined : Icons.person_outline,
                  color: usuario.ehAdmin ? TemaNice.branco : TemaNice.grafite,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(usuario.nome, style: texto.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      [usuario.email, if (usuario.criadoEm != null) 'desde ${formatarData(usuario.criadoEm)}'].join(' · '),
                      style: texto.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (usuario.ehAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  color: TemaNice.grafite,
                  child: Text('ADMIN', style: texto.labelSmall?.copyWith(color: TemaNice.branco)),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
