import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/assets.dart';
import '../controllers/catalog_controller.dart';
import '../widgets/banner_image.dart';
import '../widgets/category_section.dart';
import '../widgets/filter_panel.dart';
import '../widgets/product_grid.dart';
import '../widgets/responsive.dart';
import '../widgets/state_views.dart';

/// Catálogo completo com busca e filtros.
/// Web: barra lateral de filtros + grade. Mobile: busca + gaveta de filtros.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, this.initialCategory, this.initialQuery, this.scrollToProducts = false});

  final String? initialCategory;
  final String? initialQuery;

  /// Busca e links "ver todos os produtos": rola até a área dos produtos.
  final bool scrollToProducts;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late final TextEditingController _search;
  final _productsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialQuery ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final catalog = context.read<CatalogController>();
      catalog.applyInitial(category: widget.initialCategory, query: widget.initialQuery);
      catalog.load();
      if (widget.scrollToProducts) _scrollToProducts();
    });
  }

  void _scrollToProducts() {
    final target = _productsKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider<CatalogController>.value(
        value: context.read<CatalogController>(),
        child: const SafeArea(
          child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(24, 0, 24, 24), child: FilterPanel()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final text = Theme.of(context).textTheme;
    final products = catalog.filtered;
    final desktop = context.isDesktop;

    final searchField = TextField(
      controller: _search,
      onChanged: catalog.setQuery,
      decoration: InputDecoration(
        hintText: 'Buscar produtos...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _search.clear();
                  catalog.setQuery('');
                },
              ),
      ),
    );

    final results = catalog.loading && !catalog.loaded
        ? const LoadingView()
        : products.isEmpty
        ? EmptyState(
            icon: Icons.search_off,
            title: 'Nenhum produto encontrado',
            message: 'Tente ajustar a busca ou os filtros.',
            actionLabel: 'Limpar filtros',
            onAction: () {
              _search.clear();
              catalog.clearFilters();
            },
          )
        : ProductGrid(products: products, maxColumns: desktop ? 3 : 4);

    if (!context.isCompact) {
      // Web/tablet: banner de topo e, abaixo, filtros + produtos.
      final catalogBody = desktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 280, child: FilterPanel()),
                const SizedBox(width: 48),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('CATÁLOGO', style: text.displaySmall),
                      const SizedBox(height: 4),
                      Text('${products.length} produtos', style: text.bodySmall),
                      const SizedBox(height: 20),
                      searchField,
                      const SizedBox(height: 28),
                      results,
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('CATÁLOGO', style: text.headlineLarge),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: searchField),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(tooltip: 'Filtros', onPressed: _openFilters, icon: const Icon(Icons.tune)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('${products.length} produtos', style: text.bodySmall),
                const SizedBox(height: 16),
                results,
              ],
            );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BannerImage(
            asset: NiceAssets.catalogTop,
            fitViewport: true,
            aspectRatio: 1755 / 896,
            label: 'Explore os produtos. Ver todos os produtos',
            onTap: _scrollToProducts,
          ),
          // Margem de cima: o produto não fica colado na navbar ao rolar até aqui.
          Padding(
            key: _productsKey,
            padding: EdgeInsets.only(top: desktop ? 64 : 40),
            child: ContentWrapper(child: catalogBody),
          ),
          SizedBox(height: desktop ? 88 : 56),
        ],
      );
    }

    return Padding(
      key: _productsKey,
      padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 10),
              IconButton.filledTonal(tooltip: 'Filtros', onPressed: _openFilters, icon: const Icon(Icons.tune)),
            ],
          ),
          const SizedBox(height: 16),
          const CategorySection(),
          const SizedBox(height: 16),
          Text('${products.length} produtos', style: text.bodySmall),
          const SizedBox(height: 16),
          results,
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
