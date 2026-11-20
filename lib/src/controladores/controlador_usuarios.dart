// Controlador da página de usuários do admin.
// Lista clientes e troca o tipo de conta.

import 'package:flutter/foundation.dart';

import '../dados/usuario.dart';
import '../dados/pedido.dart';
import '../dados/repositorio_enderecos.dart';
import '../dados/repositorio_pedidos.dart';
import '../dados/repositorio_usuarios.dart';

/// Tudo o que o admin vê sobre um cliente.
class DetalhesUsuario {
  const DetalhesUsuario({required this.usuario, required this.enderecos, required this.pedidos});

  final Usuario usuario;
  final List<EnderecoSalvo> enderecos;
  final List<Pedido> pedidos;

  DetalhesUsuario copiarCom({Usuario? usuario}) =>
      DetalhesUsuario(usuario: usuario ?? this.usuario, enderecos: enderecos, pedidos: pedidos);
}

/// Lista de usuários com busca e ações do administrador.
class ControladorUsuarios extends ChangeNotifier {
  ControladorUsuarios(this._usuarios, this._enderecos, this._pedidos);

  final RepositorioUsuarios _usuarios;
  final RepositorioEnderecos _enderecos;
  final RepositorioPedidos _pedidos;

  List<Usuario> _itens = [];
  bool _carregando = false;
  String? _erro;
  String _busca = '';

  bool get carregando => _carregando;
  String? get erro => _erro;

  /// Usuários filtrados pelo nome ou email digitado.
  List<Usuario> get itens {
    final q = _busca.trim().toLowerCase();
    if (q.isEmpty) return _itens;
    return _itens
        .where((u) => u.nome.toLowerCase().contains(q) || u.email.toLowerCase().contains(q))
        .toList();
  }

  void pesquisar(String valor) {
    _busca = valor;
    notifyListeners();
  }

  /// Busca todos os perfis cadastrados.
  Future<void> carregar() async {
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      _itens = await _usuarios.buscarTodos();
    } catch (_) {
      _erro = 'Não foi possível carregar os usuários.';
    }
    _carregando = false;
    notifyListeners();
  }

  /// Junta perfil endereços e pedidos de um usuário de uma vez.
  Future<DetalhesUsuario?> detalhes(String idUsuario) async {
    try {
      final resultados = await Future.wait([
        _usuarios.buscarPorId(idUsuario),
        _enderecos.buscar(idUsuario),
        _pedidos.buscarPorUsuario(idUsuario),
      ]);
      final usuario = resultados[0] as Usuario?;
      if (usuario == null) return null;
      return DetalhesUsuario(
        usuario: usuario,
        enderecos: resultados[1] as List<EnderecoSalvo>,
        pedidos: resultados[2] as List<Pedido>,
      );
    } catch (_) {
      return null;
    }
  }

  /// Transforma um cliente em admin ou o contrário.
  /// Devolve uma mensagem de erro ou nada quando dá certo.
  Future<String?> definirPapel(Usuario usuario, PapelUsuario papel) async {
    try {
      await _usuarios.definirPapel(usuario.id, papel);
      final indice = _itens.indexWhere((u) => u.id == usuario.id);
      if (indice != -1) _itens[indice] = _itens[indice].copiarCom(papel: papel);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().contains('self')
          ? 'Você não pode remover o seu próprio acesso de administrador.'
          : 'Não foi possível alterar o perfil do usuário.';
    }
  }
}
