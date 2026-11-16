import '../config/app_config.dart';

/// Uma cor do produto com as próprias fotos (pode ter várias).
class ColorVariant {
  const ColorVariant({required this.name, this.images = const []});

  final String name;
  final List<String> images;

  ColorVariant copyWith({String? name, List<String>? images}) =>
      ColorVariant(name: name ?? this.name, images: images ?? this.images);

  Map<String, dynamic> toMap() => {'name': name, 'images': images};

  factory ColorVariant.fromMap(Map<String, dynamic> map) => ColorVariant(
        name: (map['name'] as String?) ?? '',
        images: Product._strings(map['images']),
      );
}

/// Situação do desconto de um produto num instante.
enum DiscountStatus {
  none('Sem desconto'),
  scheduled('Agendado'),
  active('Ativo'),
  expired('Encerrado');

  const DiscountStatus(this.label);
  final String label;
}

class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    this.technicalDetails = '',
    this.images = const [],
    this.colorVariants = const [],
    this.sizes = const [],
    this.stock,
    this.available = true,
    this.discountPercent = 0,
    this.discountStartsAt,
    this.discountEndsAt,
    this.isFeatured = false,
    this.isNew = false,
    this.createdAt,
  });

  /// UUID do Supabase. Produtos da FakeStoreAPI usam o prefixo "fake-".
  final String id;
  final String title;
  final String description;
  final String technicalDetails;

  /// Preço cheio (sem desconto).
  final double price;
  final String category;

  /// Fotos gerais (não ligadas a uma cor).
  final List<String> images;
  final List<ColorVariant> colorVariants;
  final List<String> sizes;

  /// Quantidade em estoque: só chega preenchida para administradores
  /// (o banco não expõe a coluna para clientes/visitantes).
  final int? stock;

  /// Coluna gerada `in_stock` (stock > 0), pública.
  final bool available;

  /// Percentual configurado pelo admin (0 = sem desconto).
  /// Só vale entre [discountStartsAt] e [discountEndsAt] (null = sem limite).
  final int discountPercent;
  final DateTime? discountStartsAt;
  final DateTime? discountEndsAt;
  final bool isFeatured;
  final bool isNew;
  final DateTime? createdAt;

  bool get isFallback => id.startsWith('fake-');
  bool get inStock => stock == null ? available : stock! > 0;

  List<String> get colors => [for (final c in colorVariants) c.name];

  /// Fotos gerais + fotos de todas as cores, sem repetição.
  List<String> get allImages {
    final seen = <String>{};
    return [
      for (final url in [...images, for (final c in colorVariants) ...c.images])
        if (seen.add(url)) url,
    ];
  }

  String get imageUrl {
    final all = allImages;
    return all.isEmpty ? '' : all.first;
  }

  /// Fotos de uma cor; se ela não tiver fotos, usa todas.
  List<String> imagesFor(String? color) {
    if (color == null) return allImages;
    for (final c in colorVariants) {
      if (c.name == color && c.images.isNotEmpty) return c.images;
    }
    return allImages;
  }

  DiscountStatus discountStatusAt(DateTime now) {
    if (discountPercent <= 0) return DiscountStatus.none;
    if (discountStartsAt != null && now.isBefore(discountStartsAt!)) return DiscountStatus.scheduled;
    if (discountEndsAt != null && !now.isBefore(discountEndsAt!)) return DiscountStatus.expired;
    return DiscountStatus.active;
  }

  DiscountStatus get discountStatus => discountStatusAt(DateTime.now());

  /// O desconto está valendo agora?
  bool get hasDiscount => discountStatus == DiscountStatus.active;

  /// Percentual em vigor agora (0 fora do período).
  int get activeDiscountPercent => hasDiscount ? discountPercent : 0;

  /// Preço que o cliente paga (já com a promoção, se estiver no período).
  double get finalPrice => _round(price * (100 - activeDiscountPercent) / 100);

  /// Preço no Pix (5% sobre o preço final).
  double get pixPrice => _round(finalPrice * (1 - AppConfig.pixDiscount));

  static double _round(double value) => (value * 100).roundToDouble() / 100;

  Product copyWith({
    String? title,
    String? description,
    String? technicalDetails,
    double? price,
    String? category,
    List<String>? images,
    List<ColorVariant>? colorVariants,
    List<String>? sizes,
    int? stock,
    int? discountPercent,
    bool? isFeatured,
    bool? isNew,
  }) {
    return Product(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      technicalDetails: technicalDetails ?? this.technicalDetails,
      price: price ?? this.price,
      category: category ?? this.category,
      images: images ?? this.images,
      colorVariants: colorVariants ?? this.colorVariants,
      sizes: sizes ?? this.sizes,
      stock: stock ?? this.stock,
      available: stock == null ? available : stock > 0,
      discountPercent: discountPercent ?? this.discountPercent,
      discountStartsAt: discountStartsAt,
      discountEndsAt: discountEndsAt,
      isFeatured: isFeatured ?? this.isFeatured,
      isNew: isNew ?? this.isNew,
      createdAt: createdAt,
    );
  }

  /// Colunas públicas de `products` (sem `stock`, que é só do admin).
  static const publicColumns =
      'id,title,description,technical_details,price,discount_percent,discount_starts_at,discount_ends_at,'
      'category,images,colors,'
      'color_variants,sizes,in_stock,is_featured,is_new,created_at,updated_at';

  factory Product.fromMap(Map<String, dynamic> map) {
    final variants = map['color_variants'];
    final stock = (map['stock'] as num?)?.toInt();
    return Product(
      id: map['id'].toString(),
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      technicalDetails: (map['technical_details'] as String?) ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      discountPercent: (map['discount_percent'] as num?)?.toInt() ?? 0,
      discountStartsAt: _date(map['discount_starts_at']),
      discountEndsAt: _date(map['discount_ends_at']),
      category: (map['category'] as String?) ?? '',
      images: _strings(map['images']),
      colorVariants: variants is List && variants.isNotEmpty
          ? [for (final v in variants) ColorVariant.fromMap(Map<String, dynamic>.from(v as Map))]
          // Produtos antigos: só nomes de cores, sem fotos próprias.
          : [for (final name in _strings(map['colors'])) ColorVariant(name: name)],
      sizes: _strings(map['sizes']),
      stock: stock,
      available: (map['in_stock'] as bool?) ?? (stock ?? 1) > 0,
      isFeatured: (map['is_featured'] as bool?) ?? false,
      isNew: (map['is_new'] as bool?) ?? false,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }

  /// Linha para INSERT/UPDATE na tabela `products` (sem id quando é novo).
  /// `images` guarda todas as fotos e `colors` só os nomes, para compatibilidade.
  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'title': title,
      'description': description,
      'technical_details': technicalDetails,
      'price': price,
      'discount_percent': discountPercent,
      'discount_starts_at': discountStartsAt?.toUtc().toIso8601String(),
      'discount_ends_at': discountEndsAt?.toUtc().toIso8601String(),
      'category': category,
      'images': allImages,
      'colors': colors,
      'color_variants': [for (final c in colorVariants) c.toMap()],
      'sizes': sizes,
      'stock': ?stock,
      'is_featured': isFeatured,
      'is_new': isNew,
    };
  }

  static const _fallbackCategories = ['Camisetas', 'Moletons', 'Calças', 'Acessórios'];
  static const _names = [
    'Kuro Essential Tee',
    'Akira Vision Tee',
    'Neon Drift Hoodie',
    'Yoru Pulse Hoodie',
    'Oni Utility Jacket',
    'Shibuya Cargo Fit',
    'Tokyo Layer Tee',
    'Nami Graphic Top',
  ];
  static const _descriptions = [
    'Minimalismo que nunca sai de cena',
    'Arte urbana com influência japonesa',
    'Vibração noturna com estética cyberpunk',
    'Batida noturna que define seu estilo',
    'Atitude e design urbano em cada detalhe',
    'Funcionalidade para dominar as ruas',
    'Camadas leves para o dia inteiro',
    'Grafismo limpo com presença street',
  ];

  /// Converte um item da FakeStoreAPI (usado só como fallback visual).
  factory Product.fromFakeStore(Map<String, dynamic> json, int index) {
    final price = ((json['price'] as num).toDouble() * 5.1).clamp(89.9, 399.9).toDouble();
    return Product(
      id: 'fake-${json['id']}',
      title: _names[index % _names.length],
      description: _descriptions[index % _descriptions.length],
      price: double.parse(price.toStringAsFixed(2)),
      category: _fallbackCategories[index % _fallbackCategories.length],
      images: [json['image'] as String],
      sizes: const ['P', 'M', 'G', 'GG'],
      isFeatured: index < 6,
      isNew: index >= 3,
    );
  }

  static DateTime? _date(dynamic value) => value == null ? null : DateTime.tryParse(value.toString())?.toLocal();

  static List<String> _strings(dynamic value) =>
      value is List ? value.map((e) => e.toString()).toList() : const [];
}
