import 'package:flutter/foundation.dart';

import '../dados/produto.dart';
import '../dados/repositorio_vitrine_reserva.dart';
import '../dados/repositorio_produtos.dart';

enum Ordenacao {
  recentes('Mais recentes'),
  menorPreco('Menor preço'),
  maiorPreco('Maior preço'),
  nome('Nome (A-Z)');

  const Ordenacao(this.rotulo);
  final String rotulo;
}

class ControladorCatalogo extends ChangeNotifier {
  ControladorCatalogo(this._produtos, this._vitrineReserva);

  static const todasCategorias = 'Ver tudo';
  static const categorias = [todasCategorias, 'Camisetas', 'Moletons', 'Calças', 'Acessórios'];
  static const tamanhos = ['P', 'M', 'G', 'GG'];

  final RepositorioProdutos _produtos;
  final RepositorioVitrineReserva _vitrineReserva;

  List<Produto> _remotos = [];
  /// Produtos de exemplo usados quando o banco está vazio.
  List<Produto> _reserva = [];
  bool _carregando = false;
  bool _carregado = false;

  String _busca = '';
  String _categoria = todasCategorias;
  String? _tamanho;
  double? _precoMaximo;
  Ordenacao _ordenacao = Ordenacao.recentes;

  bool get carregando => _carregando;
  bool get carregado => _carregado;
  String get busca => _busca;
  String get categoriaSelecionada => _categoria;
  String? get tamanhoSelecionado => _tamanho;
  Ordenacao get ordenacao => _ordenacao;

  /// Usa os produtos do banco e só cai na vitrine reserva se o banco estiver vazio.
  List<Produto> get _base => _remotos.isNotEmpty ? _remotos : _reserva;

  List<Produto> get destaques {
    final marcados = _remotos.where((p) => p.emDestaque).toList();
    return marcados.isNotEmpty ? marcados : _reserva.where((p) => p.emDestaque).toList();
  }

  List<Produto> get novidades {
    final marcados = _remotos.where((p) => p.novidade).toList();
    return marcados.isNotEmpty ? marcados : _reserva.where((p) => p.novidade).toList();
  }

  /// Tamanhos padrão seguidos dos tamanhos personalizados que o admin cadastrou.
  List<String> get tamanhosDisponiveis {
    final personalizados = <String>{
      for (final p in _base)
        for (final s in p.tamanhos)
          if (!tamanhos.contains(s)) s,
    };
    return [...tamanhos, ...personalizados];
  }

  /// Foto de capa da categoria tirada de um produto dela.
  String capaDa(String categoria) {
    for (final p in [..._base, ..._reserva]) {
      if (p.categoria == categoria && p.urlFoto.isNotEmpty) return p.urlFoto;
    }
    return '';
  }

  double get maiorPreco {
    if (_base.isEmpty) return 500;
    final maximo = _base.map((p) => p.precoFinal).reduce((a, b) => a > b ? a : b);
    return (maximo / 50).ceil() * 50.0;
  }

  double get precoMaximo => _precoMaximo ?? maiorPreco;

  List<Produto> get filtrados {
    final q = _busca.trim().toLowerCase();
    final lista = _base.where((p) {
      final bateCategoria = _categoria == todasCategorias || p.categoria == _categoria;
      final bateBusca = q.isEmpty ||
          p.titulo.toLowerCase().contains(q) ||
          p.descricao.toLowerCase().contains(q);
      final bateTamanho = _tamanho == null || p.tamanhos.contains(_tamanho);
      final batePreco = p.precoFinal <= precoMaximo;
      return bateCategoria && bateBusca && bateTamanho && batePreco;
    }).toList();

    switch (_ordenacao) {
      case Ordenacao.menorPreco:
        lista.sort((a, b) => a.precoFinal.compareTo(b.precoFinal));
      case Ordenacao.maiorPreco:
        lista.sort((a, b) => b.precoFinal.compareTo(a.precoFinal));
      case Ordenacao.nome:
        lista.sort((a, b) => a.titulo.compareTo(b.titulo));
      case Ordenacao.recentes:
        break;
    }
    return lista;
  }

  Future<void>? _emAndamento;

  /// Carrega os produtos uma vez só.
  /// Se já estiver carregando devolve o mesmo carregamento.
  Future<void> carregar({bool forcar = false}) {
    if (_emAndamento != null) return _emAndamento!;
    if (_carregado && !forcar) return Future.value();
    return _emAndamento = _carregar().whenComplete(() => _emAndamento = null);
  }

  Future<void> _carregar() async {
    _carregando = true;
    notifyListeners();

    try {
      _remotos = await _produtos.buscarTodos();
    } catch (_) {
      _remotos = [];
    }
    final precisaReserva = _remotos.isEmpty ||
        !_remotos.any((p) => p.emDestaque) ||
        !_remotos.any((p) => p.novidade);
    if (precisaReserva && _reserva.isEmpty) {
      _reserva = await _vitrineReserva.buscarProdutos();
    }

    _carregando = false;
    _carregado = true;
    notifyListeners();
  }

  Future<Produto?> encontrarPorId(String id) async {
    for (final p in [..._remotos, ..._reserva]) {
      if (p.id == id) return p;
    }
    if (id.startsWith('fake-')) return null;
    try {
      return await _produtos.buscarPorId(id);
    } catch (_) {
      return null;
    }
  }

  void aplicarFiltrosIniciais({String? categoria, String? busca}) {
    _categoria = categorias.contains(categoria) ? categoria! : todasCategorias;
    _busca = busca ?? '';
    _tamanho = null;
    _precoMaximo = null;
    _ordenacao = Ordenacao.recentes;
    notifyListeners();
  }

  void definirCategoria(String categoria) {
    _categoria = categoria;
    notifyListeners();
  }

  void definirBusca(String valor) {
    _busca = valor;
    notifyListeners();
  }

  void definirTamanho(String? tamanho) {
    _tamanho = tamanho;
    notifyListeners();
  }

  void definirPrecoMaximo(double valor) {
    _precoMaximo = valor >= maiorPreco ? null : valor;
    notifyListeners();
  }

  void definirOrdenacao(Ordenacao opcao) {
    _ordenacao = opcao;
    notifyListeners();
  }

  void limparFiltros() => aplicarFiltrosIniciais();
}
