import 'package:flutter/foundation.dart';

import '../dados/pedido.dart';
import '../dados/repositorio_enderecos.dart';

class ControladorEnderecos extends ChangeNotifier {
  ControladorEnderecos(this._repositorio);

  final RepositorioEnderecos _repositorio;

  List<EnderecoSalvo> _itens = [];
  String? _idUsuario;
  bool _carregando = false;
  bool _salvando = false;
  String? _erro;
  int _fichaCarga = 0;

  List<EnderecoSalvo> get itens => _itens;
  bool get carregando => _carregando;
  bool get salvando => _salvando;
  String? get erro => _erro;

  void vincularUsuario(String? idUsuario) {
    if (_idUsuario == idUsuario) return;
    _idUsuario = idUsuario;
    _itens = [];
    final token = ++_fichaCarga;
    Future.microtask(() async {
      if (token != _fichaCarga) return;
      if (idUsuario == null) {
        notifyListeners();
        return;
      }
      await _carregar(idUsuario, token);
    });
  }

  Future<void> recarregar() async {
    final idUsuario = _idUsuario;
    if (idUsuario != null) await _carregar(idUsuario, ++_fichaCarga);
  }

  /// Busca os endereços no banco e ignora respostas antigas.
  Future<void> _carregar(String idUsuario, int token) async {
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      final itens = await _repositorio.buscar(idUsuario);
      if (token != _fichaCarga) return;
      _itens = itens;
    } catch (_) {
      if (token != _fichaCarga) return;
      _erro = 'Não foi possível carregar seus endereços.';
    }
    _carregando = false;
    notifyListeners();
  }

  Future<EnderecoSalvo?> salvar(EnderecoSalvo endereco) async {
    final idUsuario = _idUsuario;
    if (idUsuario == null) return null;
    _salvando = true;
    _erro = null;
    notifyListeners();
    try {
      final salvo = await _repositorio.salvar(idUsuario, endereco);
      final indice = _itens.indexWhere((a) => a.id == salvo.id);
      _itens = indice == -1 ? [..._itens, salvo] : ([..._itens]..[indice] = salvo);
      return salvo;
    } catch (_) {
      _erro = 'Não foi possível salvar o endereço.';
      return null;
    } finally {
      _salvando = false;
      notifyListeners();
    }
  }

  Future<bool> excluir(EnderecoSalvo endereco) async {
    try {
      await _repositorio.excluir(endereco.id);
      _itens = _itens.where((a) => a.id != endereco.id).toList();
      notifyListeners();
      return true;
    } catch (_) {
      _erro = 'Não foi possível excluir o endereço.';
      notifyListeners();
      return false;
    }
  }

  Future<ResultadoCep?> consultarCep(String cep) async {
    try {
      return await _repositorio.consultarCep(cep);
    } catch (_) {
      return null;
    }
  }
}
