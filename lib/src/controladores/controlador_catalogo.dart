import 'package:flutter/foundation.dart';

import '../dados/classificador_categorias.dart';
import '../dados/indice_busca.dart';
import '../dados/produto.dart';
import '../dados/repositorio_categorias.dart';
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
  ControladorCatalogo(this._produtos, this._vitrineReserva, this._categoriasRepositorio);

  static const todasCategorias = 'Ver tudo';
  static const semCategoria = 'Sem categoria';

  /// Usadas enquanto o banco não responde ou se a tabela de categorias ainda não existir.
  static const categoriasPadrao = ['Camisetas', 'Moletons', 'Calças', 'Acessórios'];
  static const tamanhos = ['P', 'M', 'G', 'GG'];

  final RepositorioProdutos _produtos;
  final RepositorioVitrineReserva _vitrineReserva;
  final RepositorioCategorias _categoriasRepositorio;

  List<String> _categorias = [...categoriasPadrao, semCategoria];

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

  /// Todas as categorias cadastradas para o admin escolher no produto.
  List<String> get categoriasCadastro => _categorias;

  /// Categorias mostradas na loja.
  /// Sem categoria só aparece quando algum produto está nela.
  List<String> get categorias => [
    for (final c in _categorias)
      if (c != semCategoria || _base.any((p) => p.categoria == semCategoria)) c,
  ];

  List<String> get categoriasFiltro => [todasCategorias, ...categorias];

  /// Produtos reais do banco em uma categoria.
  int qtdProdutosDa(String categoria) => _remotos.where((p) => p.categoria == categoria).length;

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

  static const _classificador = ClassificadorCategorias();

  /// Abaixo disso o modelo está em dúvida e a categoria não influencia a busca.
  static const confiancaMinima = 0.6;

  /// Fração da nota do melhor resultado que um produto precisa ter para aparecer.
  static const relevanciaMinima = 0.3;

  IndiceBusca? _indice;
  List<Produto>? _indiceDe;

  /// Refeito só quando a lista de produtos muda.
  IndiceBusca get _indiceBusca {
    if (!identical(_indiceDe, _base)) {
      _indiceDe = _base;
      _indice = IndiceBusca(_base);
    }
    return _indice!;
  }

  /// Categoria que o modelo de PLN acha que o cliente procura.
  PrevisaoCategoria? get categoriaPrevista {
    if (_busca.trim().isEmpty) return null;
    final previsao = _classificador.prever(_busca);
    if (previsao == null || previsao.confianca < confiancaMinima) return null;
    return categorias.contains(previsao.categoria) ? previsao : null;
  }

  /// Relevância de cada produto: texto parecido mais um bônus para a categoria prevista.
  Map<String, double> _relevancia(String consulta) {
    final pontos = _indiceBusca.pontuar(consulta);
    final previsao = categoriaPrevista;
    if (previsao != null) {
      for (final p in _base) {
        if (p.categoria == previsao.categoria) pontos[p.id] = (pontos[p.id] ?? 0) + 0.3 * previsao.confianca;
      }
    }
    // Some com quem só bateu de raspão como uma cor parecida quando há resultados bem melhores
    if (pontos.isNotEmpty) {
      final melhor = pontos.values.reduce((a, b) => a > b ? a : b);
      pontos.removeWhere((_, nota) => nota < melhor * relevanciaMinima);
    }
    return pontos;
  }

  List<Produto> get filtrados {
    final relevancia = _busca.trim().isEmpty ? null : _relevancia(_busca);
    final lista = _base.where((p) {
      final bateCategoria = _categoria == todasCategorias || p.categoria == _categoria;
      final bateBusca = relevancia == null || relevancia.containsKey(p.id);
      final bateTamanho = _tamanho == null || p.tamanhos.contains(_tamanho);
      final batePreco = p.precoFinal <= precoMaximo;
      return bateCategoria && bateBusca && bateTamanho && batePreco;
    }).toList();

    if (relevancia != null && _ordenacao == Ordenacao.recentes) {
      lista.sort((a, b) => relevancia[b.id]!.compareTo(relevancia[a.id]!));
      return lista;
    }
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
    await _carregarCategorias();
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

  Future<void> _carregarCategorias() async {
    try {
      final lista = await _categoriasRepositorio.buscarTodas();
      if (lista.isNotEmpty) _categorias = lista;
    } catch (_) {
      // Sem a tabela de categorias a loja segue com a lista padrão.
    }
  }

  /// Devolve uma mensagem de erro ou nada quando a categoria foi criada.
  Future<String?> criarCategoria(String nome) async {
    final limpo = nome.trim();
    if (limpo.isEmpty) return 'Informe o nome da categoria.';
    if (limpo == todasCategorias) return 'Esse nome é reservado.';
    if (_categorias.any((c) => c.toLowerCase() == limpo.toLowerCase())) {
      return 'Já existe uma categoria com esse nome.';
    }
    try {
      await _categoriasRepositorio.criar(limpo);
    } on ErroCategoria catch (e) {
      return e.mensagem;
    } catch (_) {
      return 'Não foi possível criar a categoria.';
    }
    await _carregarCategorias();
    notifyListeners();
    return null;
  }

  /// Os produtos da categoria vão para Sem categoria.
  /// Devolve uma mensagem de erro ou nada quando deu certo.
  Future<String?> excluirCategoria(String nome) async {
    if (nome == semCategoria) return 'A categoria Sem categoria não pode ser excluída.';
    try {
      await _categoriasRepositorio.excluir(nome);
    } catch (_) {
      return 'Não foi possível excluir a categoria.';
    }
    if (_categoria == nome) _categoria = todasCategorias;
    await carregar(forcar: true);
    return null;
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
    // A categoria do endereço é aceita como veio porque a lista pode ainda não ter carregado.
    _categoria = (categoria == null || categoria.trim().isEmpty) ? todasCategorias : categoria;
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
