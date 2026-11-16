import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/catalog_controller.dart';
import '../models/product.dart';
import '../theme/nice_theme.dart';
import '../utils/feedback.dart';
import '../utils/formatters.dart';
import '../utils/navigation.dart';
import '../widgets/breadcrumbs.dart';
import '../widgets/nice_network_image.dart';
import '../widgets/price_tag.dart';
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
  int? _adminStock;
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
    final isAdmin = context.read<AuthController>().isAdmin;
    final admin = context.read<AdminController>();
    if (!catalog.loaded) await catalog.load();
    final product = await catalog.findById(widget.productId);
    // Estoque só é lido (e exibido) para administradores.
    final stock = isAdmin && product != null && !product.isFallback
        ? (await admin.findById(product.id))?.stock
        : null;
    if (!mounted) return;
    setState(() {
      _product = product;
      _adminStock = stock;
      _loading = false;
      // Uma única opção já vem selecionada.
      if (product != null && product.sizes.length == 1) _size = product.sizes.first;
      if (product != null && product.colors.length == 1) _color = product.colors.first;
    });
  }

  /// Clicar na cor selecionada desmarca e volta a mostrar todas as fotos.
  void _selectColor(String color) {
    setState(() {
      _color = _color == color ? null : color;
      _imageIndex = 0; // a foto grande passa a ser a primeira da cor (ou do produto)
    });
  }

  void _addToCart(Product product) {
    // Visitante vai para o login e volta para esta página.
    if (!context.requireLogin()) return;

    if (product.sizes.isNotEmpty && _size == null) {
      showMessage(context, 'Escolha um tamanho.');
      return;
    }
    if (product.colors.isNotEmpty && _color == null) {
      showMessage(context, 'Escolha uma cor.');
      return;
    }
    final variant = [?_size, ?_color].join(' / ');
    context.read<CartController>().add(product, size: variant);
    showAddedToCart(context, product.title);
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
      // Ao escolher uma cor, a galeria mostra as fotos dessa cor.
      images: product.imagesFor(_color),
      index: _imageIndex,
      discountPercent: product.activeDiscountPercent,
      onSelect: (i) => setState(() => _imageIndex = i),
    );
    final info = _buildInfo(context, product);
    final details = product.technicalDetails.trim().isEmpty ? null : _TechnicalDetails(text: product.technicalDetails);
    final crumbs = Breadcrumbs(
      items: [
        const Crumb('Home', '/'),
        const Crumb('Catálogo', '/catalogo'),
        if (product.category.isNotEmpty)
          Crumb(product.category, catalogPath(category: product.category, toProducts: true)),
        Crumb(product.title),
      ],
    );

    return ContentWrapper(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.isDesktop ? 40 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            crumbs,
            SizedBox(height: context.isDesktop ? 28 : 16),
            if (context.isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: gallery),
                  const SizedBox(width: 56),
                  Expanded(flex: 5, child: info),
                ],
              )
            else ...[
              gallery,
              const SizedBox(height: 24),
              info,
            ],
            if (details != null) ...[
              SizedBox(height: context.isDesktop ? 56 : 32),
              details,
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, Product product) {
    final text = Theme.of(context).textTheme;
    final isAdmin = context.watch<AuthController>().isAdmin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.title.toUpperCase(), style: text.headlineLarge),
        const SizedBox(height: 14),
        PriceTag(product: product, large: true),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            style: text.bodyMedium,
            children: [
              TextSpan(text: formatCurrency(product.pixPrice), style: text.titleSmall?.copyWith(color: NiceTheme.success)),
              TextSpan(text: ' no Pix (${(AppConfig.pixDiscount * 100).round()}% de desconto)'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _InfoLine(
          icon: Icons.local_shipping_outlined,
          text: 'Frete grátis em compras a partir de ${formatCurrency(AppConfig.freeShippingThreshold)}',
        ),
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
        if (product.colorVariants.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('COR${_color == null ? '' : ': ${_color!.toUpperCase()}'}', style: text.labelMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final variant in product.colorVariants)
                ChoiceChip(
                  avatar: variant.images.isEmpty
                      ? null
                      : ClipOval(child: NiceNetworkImage(url: variant.images.first, fit: BoxFit.cover)),
                  label: Text(variant.name),
                  selected: _color == variant.name,
                  labelStyle: NiceTheme.chipLabel(selected: _color == variant.name),
                  onSelected: (_) => _selectColor(variant.name),
                ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        if (!product.inStock)
          Text('Produto esgotado', style: text.titleSmall?.copyWith(color: NiceTheme.red))
        else if (isAdmin && _adminStock != null)
          _InfoLine(icon: Icons.inventory_2_outlined, text: '$_adminStock em estoque (visível só para administradores)'),
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: NiceTheme.red),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}

class _TechnicalDetails extends StatelessWidget {
  const _TechnicalDetails({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NiceTheme.lightGray,
        borderRadius: BorderRadius.circular(NiceTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DETALHES TÉCNICOS', style: theme.labelMedium),
          const SizedBox(height: 14),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: theme.bodyMedium?.copyWith(color: NiceTheme.red)),
                  Expanded(child: Text(line, style: theme.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.images,
    required this.index,
    required this.onSelect,
    required this.discountPercent,
  });

  final List<String> images;
  final int index;
  final int discountPercent;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final urls = images.isEmpty ? const [''] : images;
    final selected = index.clamp(0, urls.length - 1);

    final main = AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(NiceTheme.radius),
              child: ColoredBox(
                color: NiceTheme.softGray,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: NiceNetworkImage(key: ValueKey(urls[selected]), url: urls[selected]),
                ),
              ),
            ),
          ),
          if (discountPercent > 0)
            Positioned(right: 12, top: 12, child: DiscountBadge(percent: discountPercent)),
        ],
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
              border: Border.all(color: i == selected ? NiceTheme.red : NiceTheme.softGray, width: 2),
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
