import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/cart_controller.dart';
import '../controllers/catalog_controller.dart';
import '../models/product.dart';
import '../theme/nice_theme.dart';
import '../utils/formatters.dart';
import '../utils/navigation.dart';
import '../widgets/nice_network_image.dart';
import '../widgets/responsive.dart';
import '../widgets/state_views.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _loading = true;
  String? _size;
  String? _color;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final catalog = context.read<CatalogController>();
    if (!catalog.loaded) await catalog.load();
    final product = await catalog.findById(widget.productId);
    if (!mounted) return;
    setState(() {
      _product = product;
      _loading = false;
    });
  }

  void _addToCart(Product product) {
    // Visitante vai para o login e volta para esta página.
    if (!context.requireLogin()) return;

    final messenger = ScaffoldMessenger.of(context);
    if (product.sizes.isNotEmpty && _size == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Escolha um tamanho.')));
      return;
    }
    if (product.colors.isNotEmpty && _color == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Escolha uma cor.')));
      return;
    }
    final variant = [if (_size != null) _size!, if (_color != null) _color!].join(' / ');
    context.read<CartController>().add(product, size: variant);
    messenger.showSnackBar(
      SnackBar(
        content: Text('${product.title} adicionado ao carrinho'),
        action: SnackBarAction(label: 'VER CARRINHO', onPressed: () => context.go('/carrinho')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    final product = _product;
    if (product == null) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'Produto não encontrado',
        actionLabel: 'Ver catálogo',
        onAction: () => context.go('/catalogo'),
      );
    }

    final gallery = _Gallery(
      images: product.images,
      index: _imageIndex,
      onSelect: (i) => setState(() => _imageIndex = i),
    );
    final info = _buildInfo(context, product);

    return ContentWrapper(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.isDesktop ? 48 : 8),
        child: context.isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: gallery),
                  const SizedBox(width: 56),
                  Expanded(flex: 5, child: info),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [gallery, const SizedBox(height: 24), info, const SizedBox(height: 32)],
              ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, Product product) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.category.toUpperCase(), style: text.labelMedium),
        const SizedBox(height: 8),
        Text(product.title.toUpperCase(), style: text.headlineLarge),
        const SizedBox(height: 12),
        Text(formatCurrency(product.price), style: text.headlineMedium),
        const SizedBox(height: 20),
        Text(product.description, style: text.bodyLarge),
        if (product.sizes.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text('TAMANHO', style: text.labelMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final size in product.sizes)
                ChoiceChip(
                  label: Text(size),
                  selected: _size == size,
                  labelStyle: NiceTheme.chipLabel(selected: _size == size),
                  onSelected: (_) => setState(() => _size = size),
                ),
            ],
          ),
        ],
        if (product.colors.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('COR', style: text.labelMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final color in product.colors)
                ChoiceChip(
                  label: Text(color),
                  selected: _color == color,
                  labelStyle: NiceTheme.chipLabel(selected: _color == color),
                  onSelected: (_) => setState(() => _color = color),
                ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        Text(
          product.inStock ? '${product.stock} em estoque' : 'Produto esgotado',
          style: text.bodySmall,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: product.inStock ? () => _addToCart(product) : null,
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(product.inStock ? 'ADICIONAR AO CARRINHO' : 'ESGOTADO'),
          ),
        ),
      ],
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.images, required this.index, required this.onSelect});

  final List<String> images;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final urls = images.isEmpty ? const [''] : images;
    final current = urls[index.clamp(0, urls.length - 1)];

    final main = AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(NiceTheme.radius),
        child: ColoredBox(color: NiceTheme.softGray, child: NiceNetworkImage(url: current)),
      ),
    );
    if (urls.length < 2) return main;

    final thumbs = [
      for (var i = 0; i < urls.length; i++)
        GestureDetector(
          onTap: () => onSelect(i),
          child: Container(
            width: 72,
            height: 72,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(NiceTheme.radius),
              border: Border.all(color: i == index ? NiceTheme.red : NiceTheme.softGray, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(NiceTheme.radius - 2),
              child: NiceNetworkImage(url: urls[i], fit: BoxFit.cover),
            ),
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        main,
        const SizedBox(height: 12),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: thumbs)),
      ],
    );
  }
}
