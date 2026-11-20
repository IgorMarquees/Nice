// Controlador do painel de produtos do administrador.
// Carrega a lista com estoque e salva exclui e aplica descontos.

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../dados/produto.dart';
import '../dados/repositorio_produtos.dart';
import '../dados/repositorio_fotos.dart';

/// Cor em edição no formulário com as fotos que já existem e as fotos novas que ainda vão subir.
class RascunhoVariante {
  const RascunhoVariante({required this.nome, this.fotos = const [], this.novosArquivos = const []});

  final String nome;
  final List<String> fotos;
  final List<XFile> novosArquivos;
}

/// Guarda o estado da tela de produtos do admin e avisa a interface quando algo muda.
class ControladorAdmin extends ChangeNotifier {
  ControladorAdmin(this._produtos, this._armazenamento);

  final RepositorioProdutos _produtos;
  final RepositorioFotos _armazenamento;

  List<Produto> _itens = [];
  bool _carregando = false;
  bool _salvando = false;
  String? _erro;
  String _busca = '';

  bool get carregando => _carregando;
  bool get salvando => _salvando;
  String? get erro => _erro;

  /// Todos os produtos sem o filtro da busca.
  List<Produto> get todos => _itens;

  /// Produtos filtrados pelo texto digitado na busca.
  List<Produto> get itens {
    final q = _busca.trim().toLowerCase();
    if (q.isEmpty) return _itens;
    return _itens
        .where((p) => p.titulo.toLowerCase().contains(q) || p.categoria.toLowerCase().contains(q))
        .toList();
  }

  /// Atualiza o texto da busca e redesenha a lista.
  void pesquisar(String valor) {
    _busca = valor;
    notifyListeners();
  }

  /// Busca os produtos no banco já com a quantidade em estoque.
  Future<void> carregar() async {
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      _itens = await _produtos.buscarTodosAdmin();
    } catch (_) {
      _erro = 'Não foi possível carregar os produtos. Rode o SQL de atualização no Supabase.';
    }
    _carregando = false;
    notifyListeners();
  }

  /// Procura um produto na lista e carrega a lista se ela ainda estiver vazia.
  Future<Produto?> encontrarPorId(String id) async {
    if (_itens.isEmpty) await carregar();
    for (final p in _itens) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Envia as fotos novas para o armazenamento e depois grava o produto no banco.
  Future<bool> salvar(
    Produto produto, {
    List<XFile> novasFotos = const [],
    List<RascunhoVariante> variantes = const [],
  }) async {
    _salvando = true;
    _erro = null;
    notifyListeners();
    try {
      final gerais = [...produto.fotos];
      for (final arquivo in novasFotos) {
        gerais.add(await _armazenamento.enviarFotoProduto(arquivo));
      }
      final variantesCor = <VarianteCor>[];
      for (final rascunho in variantes) {
        final urls = [...rascunho.fotos];
        for (final arquivo in rascunho.novosArquivos) {
          urls.add(await _armazenamento.enviarFotoProduto(arquivo));
        }
        variantesCor.add(VarianteCor(nome: rascunho.nome, fotos: urls));
      }
      await _produtos.salvar(produto.copiarCom(fotos: gerais, variantesCor: variantesCor));
      await carregar();
      return true;
    } catch (_) {
      _erro = 'Não foi possível salvar o produto. Verifique se você é administrador.';
      return false;
    } finally {
      _salvando = false;
      notifyListeners();
    }
  }

  /// Liga ou desliga Destaque e Novidade.
  /// A tela muda na hora e volta atrás se o banco recusar.
  Future<bool> definirMarcacoes(Produto produto, {bool? emDestaque, bool? novidade}) async {
    final indice = _itens.indexWhere((p) => p.id == produto.id);
    if (indice == -1) return false;
    final anterior = _itens[indice];
    _itens[indice] = anterior.copiarCom(emDestaque: emDestaque, novidade: novidade);
    notifyListeners();
    try {
      await _produtos.definirMarcacoes(produto.id, emDestaque: emDestaque, novidade: novidade);
      return true;
    } catch (_) {
      _itens[indice] = anterior;
      _erro = 'Não foi possível atualizar o produto.';
      notifyListeners();
      return false;
    }
  }

  /// Aplica o mesmo desconto com início e fim em um ou vários produtos.
  Future<bool> aplicarDesconto(List<String> ids, {required int percentual, DateTime? comecaEm, DateTime? terminaEm}) async {
    return _emMassa(() => _produtos.definirDesconto(ids, percentual: percentual, comecaEm: comecaEm, terminaEm: terminaEm),
        'Não foi possível aplicar o desconto.');
  }

  /// Tira o desconto de um ou vários produtos.
  Future<bool> cancelarDesconto(List<String> ids) {
    return _emMassa(() => _produtos.definirDesconto(ids, percentual: 0), 'Não foi possível cancelar o desconto.');
  }

  /// Executa uma ação em massa e recarrega a lista no final.
  Future<bool> _emMassa(Future<void> Function() acao, String mensagemErro) async {
    _salvando = true;
    _erro = null;
    notifyListeners();
    try {
      await acao();
      await carregar();
      return true;
    } catch (_) {
      _erro = mensagemErro;
      return false;
    } finally {
      _salvando = false;
      notifyListeners();
    }
  }

  /// Exclui o produto do banco e da lista.
  Future<bool> excluir(Produto produto) async {
    try {
      await _produtos.excluir(produto.id);
      _itens.removeWhere((p) => p.id == produto.id);
      notifyListeners();
      return true;
    } catch (_) {
      _erro = 'Não foi possível excluir o produto.';
      notifyListeners();
      return false;
    }
  }
}
