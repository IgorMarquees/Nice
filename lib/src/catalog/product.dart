class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
  });

  final int id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final String category;

  factory Product.fromFakeStore(Map<String, dynamic> json, int index) {
    final names = [
      'Kuro Essential Tee',
      'Akira Vision Tee',
      'Neon Drift Hoodie',
      'Yoru Pulse Hoodie',
      'Oni Utility Jacket',
      'Shibuya Cargo Fit',
      'Tokyo Layer Tee',
      'Nami Graphic Top',
    ];
    final descriptions = [
      'Minimalismo que nunca sai de cena',
      'Arte urbana com influencia japonesa',
      'Vibracao noturna com estetica cyberpunk',
      'Batida noturna que define seu estilo',
      'Atitude e design urbano em cada detalhe',
      'Funcionalidade para dominar as ruas',
      'Camadas leves para o dia inteiro',
      'Grafismo limpo com presenca street',
    ];

    return Product(
      id: (json['id'] as num).toInt(),
      title: names[index % names.length],
      description: descriptions[index % descriptions.length],
      price: ((json['price'] as num).toDouble() * 5.1).clamp(89.9, 399.9).toDouble(),
      imageUrl: json['image'] as String,
      category: (json['category'] as String).contains('women') ? 'Camisetas' : 'Moletons',
    );
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: (map['id'] as num).toInt(),
      title: map['title'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      imageUrl: map['imageUrl'] as String,
      category: map['category'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
    };
  }
}
