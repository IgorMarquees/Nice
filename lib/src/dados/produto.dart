import '../nucleo/configuracao.dart';

class VarianteCor {
  const VarianteCor({required this.nome, this.fotos = const []});

  final String nome;
  final List<String> fotos;

  VarianteCor copiarCom({String? nome, List<String>? fotos}) =>
      VarianteCor(nome: nome ?? this.nome, fotos: fotos ?? this.fotos);

  Map<String, dynamic> paraMapa() => {'name': nome, 'images': fotos};

  factory VarianteCor.doMapa(Map<String, dynamic> mapa) => VarianteCor(
        nome: (mapa['name'] as String?) ?? '',
        fotos: Produto._textos(mapa['images']),
      );
}

enum SituacaoDesconto {
  nenhum('Sem desconto'),
  agendado('Agendado'),
  ativo('Ativo'),
  encerrado('Encerrado');

  const SituacaoDesconto(this.rotulo);
  final String rotulo;
}

class Produto {
  const Produto({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.preco,
    required this.categoria,
    this.detalhesTecnicos = '',
    this.fotos = const [],
    this.variantesCor = const [],
    this.tamanhos = const [],
    this.estoque,
    this.disponivel = true,
    this.percentualDesconto = 0,
    this.inicioDesconto,
    this.fimDesconto,
    this.emDestaque = false,
    this.novidade = false,
    this.criadoEm,
  });

  /// Os produtos da vitrine reserva usam ids que começam com fake.
  final String id;
  final String titulo;
  final String descricao;
  final String detalhesTecnicos;

  final double preco;
  final String categoria;

  /// Fotos gerais que não pertencem a nenhuma cor.
  final List<String> fotos;
  final List<VarianteCor> variantesCor;
  final List<String> tamanhos;

  /// Quantidade em estoque.
  /// Só chega preenchida para o administrador.
  final int? estoque;

  /// Diz se ainda tem estoque e pode ser lida por qualquer pessoa.
  final bool disponivel;

  /// Desconto em porcentagem que só vale entre o início e o fim.
  final int percentualDesconto;
  final DateTime? inicioDesconto;
  final DateTime? fimDesconto;
  final bool emDestaque;
  final bool novidade;
  final DateTime? criadoEm;

  bool get ehReserva => id.startsWith('fake-');
  bool get temEstoque => estoque == null ? disponivel : estoque! > 0;

  List<String> get cores => [for (final c in variantesCor) c.nome];

  List<String> get todasFotos {
    final vistas = <String>{};
    return [
      for (final url in [...fotos, for (final c in variantesCor) ...c.fotos])
        if (vistas.add(url)) url,
    ];
  }

  String get urlFoto {
    final todos = todasFotos;
    return todos.isEmpty ? '' : todos.first;
  }

  /// Fotos da cor escolhida.
  /// Se a cor não tiver fotos mostra todas.
  List<String> fotosDaCor(String? cor) {
    if (cor == null) return todasFotos;
    for (final c in variantesCor) {
      if (c.nome == cor && c.fotos.isNotEmpty) return c.fotos;
    }
    return todasFotos;
  }

  SituacaoDesconto situacaoDescontoEm(DateTime agora) {
    if (percentualDesconto <= 0) return SituacaoDesconto.nenhum;
    if (inicioDesconto != null && agora.isBefore(inicioDesconto!)) return SituacaoDesconto.agendado;
    if (fimDesconto != null && !agora.isBefore(fimDesconto!)) return SituacaoDesconto.encerrado;
    return SituacaoDesconto.ativo;
  }

  SituacaoDesconto get situacaoDesconto => situacaoDescontoEm(DateTime.now());

  bool get temDesconto => situacaoDesconto == SituacaoDesconto.ativo;

  int get percentualDescontoAtivo => temDesconto ? percentualDesconto : 0;

  double get precoFinal => _arredondar(preco * (100 - percentualDescontoAtivo) / 100);

  double get precoPix => _arredondar(precoFinal * (1 - Configuracao.descontoPix));

  static double _arredondar(double valor) => (valor * 100).roundToDouble() / 100;

  Produto copiarCom({
    String? titulo,
    String? descricao,
    String? detalhesTecnicos,
    double? preco,
    String? categoria,
    List<String>? fotos,
    List<VarianteCor>? variantesCor,
    List<String>? tamanhos,
    int? estoque,
    int? percentualDesconto,
    bool? emDestaque,
    bool? novidade,
  }) {
    return Produto(
      id: id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      detalhesTecnicos: detalhesTecnicos ?? this.detalhesTecnicos,
      preco: preco ?? this.preco,
      categoria: categoria ?? this.categoria,
      fotos: fotos ?? this.fotos,
      variantesCor: variantesCor ?? this.variantesCor,
      tamanhos: tamanhos ?? this.tamanhos,
      estoque: estoque ?? this.estoque,
      disponivel: estoque == null ? disponivel : estoque > 0,
      percentualDesconto: percentualDesconto ?? this.percentualDesconto,
      inicioDesconto: inicioDesconto,
      fimDesconto: fimDesconto,
      emDestaque: emDestaque ?? this.emDestaque,
      novidade: novidade ?? this.novidade,
      criadoEm: criadoEm,
    );
  }

  /// Colunas que qualquer pessoa pode ler.
  /// O estoque fica de fora porque só o admin pode ver.
  static const colunasPublicas =
      'id,title,description,technical_details,price,discount_percent,discount_starts_at,discount_ends_at,'
      'category,images,colors,'
      'color_variants,sizes,in_stock,is_featured,is_new,created_at,updated_at';

  factory Produto.doMapa(Map<String, dynamic> mapa) {
    final variantes = mapa['color_variants'];
    final estoque = (mapa['stock'] as num?)?.toInt();
    return Produto(
      id: mapa['id'].toString(),
      titulo: (mapa['title'] as String?) ?? '',
      descricao: (mapa['description'] as String?) ?? '',
      detalhesTecnicos: (mapa['technical_details'] as String?) ?? '',
      preco: (mapa['price'] as num?)?.toDouble() ?? 0,
      percentualDesconto: (mapa['discount_percent'] as num?)?.toInt() ?? 0,
      inicioDesconto: _data(mapa['discount_starts_at']),
      fimDesconto: _data(mapa['discount_ends_at']),
      categoria: (mapa['category'] as String?) ?? '',
      fotos: _textos(mapa['images']),
      variantesCor: variantes is List && variantes.isNotEmpty
          ? [for (final v in variantes) VarianteCor.doMapa(Map<String, dynamic>.from(v as Map))]
          : [for (final nome in _textos(mapa['colors'])) VarianteCor(nome: nome)],
      tamanhos: _textos(mapa['sizes']),
      estoque: estoque,
      disponivel: (mapa['in_stock'] as bool?) ?? (estoque ?? 1) > 0,
      emDestaque: (mapa['is_featured'] as bool?) ?? false,
      novidade: (mapa['is_new'] as bool?) ?? false,
      criadoEm: DateTime.tryParse(mapa['created_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> paraMapa() {
    return {
      if (id.isNotEmpty) 'id': id,
      'title': titulo,
      'description': descricao,
      'technical_details': detalhesTecnicos,
      'price': preco,
      'discount_percent': percentualDesconto,
      'discount_starts_at': inicioDesconto?.toUtc().toIso8601String(),
      'discount_ends_at': fimDesconto?.toUtc().toIso8601String(),
      'category': categoria,
      'images': todasFotos,
      'colors': cores,
      'color_variants': [for (final c in variantesCor) c.paraMapa()],
      'sizes': tamanhos,
      'stock': ?estoque,
      'is_featured': emDestaque,
      'is_new': novidade,
    };
  }

  static const _categoriasReserva = ['Camisetas', 'Moletons', 'Calças', 'Acessórios'];
  static const _nomes = [
    'Kuro Essential Tee',
    'Akira Vision Tee',
    'Neon Drift Hoodie',
    'Yoru Pulse Hoodie',
    'Oni Utility Jacket',
    'Shibuya Cargo Fit',
    'Tokyo Layer Tee',
    'Nami Graphic Top',
  ];
  static const _descricoes = [
    'Minimalismo que nunca sai de cena',
    'Arte urbana com influência japonesa',
    'Vibração noturna com estética cyberpunk',
    'Batida noturna que define seu estilo',
    'Atitude e design urbano em cada detalhe',
    'Funcionalidade para dominar as ruas',
    'Camadas leves para o dia inteiro',
    'Grafismo limpo com presença street',
  ];

  /// Converte um item da FakeStoreAPI em produto de exemplo.
  factory Produto.daVitrineReserva(Map<String, dynamic> json, int indice) {
    final preco = ((json['price'] as num).toDouble() * 5.1).clamp(89.9, 399.9).toDouble();
    return Produto(
      id: 'fake-${json['id']}',
      titulo: _nomes[indice % _nomes.length],
      descricao: _descricoes[indice % _descricoes.length],
      preco: double.parse(preco.toStringAsFixed(2)),
      categoria: _categoriasReserva[indice % _categoriasReserva.length],
      fotos: [json['image'] as String],
      tamanhos: const ['P', 'M', 'G', 'GG'],
      emDestaque: indice < 6,
      novidade: indice >= 3,
    );
  }

  static DateTime? _data(dynamic valor) => valor == null ? null : DateTime.tryParse(valor.toString())?.toLocal();

  static List<String> _textos(dynamic valor) =>
      valor is List ? valor.map((e) => e.toString()).toList() : const [];
}
