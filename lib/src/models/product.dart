class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    this.images = const [],
    this.colors = const [],
    this.sizes = const [],
    this.stock = 0,
    this.isFeatured = false,
    this.isNew = false,
    this.createdAt,
  });

  /// UUID do Supabase. Produtos da FakeStoreAPI usam o prefixo "fake-".
  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final List<String> images;
  final List<String> colors;
  final List<String> sizes;
  final int stock;
  final bool isFeatured;
  final bool isNew;
  final DateTime? createdAt;

  bool get isFallback => id.startsWith('fake-');
  bool get inStock => stock > 0;
  String get imageUrl => images.isEmpty ? '' : images.first;

  Product copyWith({
    String? title,
    String? description,
    double? price,
    String? category,
    List<String>? images,
    List<String>? colors,
    List<String>? sizes,
    int? stock,
    bool? isFeatured,
    bool? isNew,
  }) {
    return Product(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      images: images ?? this.images,
      colors: colors ?? this.colors,
      sizes: sizes ?? this.sizes,
      stock: stock ?? this.stock,
      isFeatured: isFeatured ?? this.isFeatured,
      isNew: isNew ?? this.isNew,
      createdAt: createdAt,
    );
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'].toString(),
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      category: (map['category'] as String?) ?? '',
      images: _strings(map['images']),
      colors: _strings(map['colors']),
      sizes: _strings(map['sizes']),
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      isFeatured: (map['is_featured'] as bool?) ?? false,
      isNew: (map['is_new'] as bool?) ?? false,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }

  /// Linha para INSERT/UPDATE na tabela `products` (sem id quando é novo).
  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'images': images,
      'colors': colors,
      'sizes': sizes,
      'stock': stock,
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
      stock: 20,
      isFeatured: index < 6,
      isNew: index >= 3,
    );
  }

  static List<String> _strings(dynamic value) =>
      value is List ? value.map((e) => e.toString()).toList() : const [];
}
