import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/assets.dart';
import '../controllers/catalog_controller.dart';
import '../models/product.dart';
import '../theme/nice_theme.dart';
import '../utils/navigation.dart';
import '../widgets/banner_image.dart';
import '../widgets/nice_network_image.dart';
import '../widgets/product_carousel.dart';
import '../widgets/responsive.dart';
import '../widgets/section_header.dart';
import '../widgets/state_views.dart';

class NewArrivalsScreen extends StatelessWidget {
  const NewArrivalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final desktop = context.isDesktop;
    final arrivals = catalog.newArrivals;
    final spotlight = catalog.featured.isNotEmpty ? catalog.featured.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BannerImage(
          asset: NiceAssets.newArrivalsTop,
          fitViewport: true,
          aspectRatio: 2876 / 1472,
          label: 'Just dropped. Ver todos os lançamentos',
          onTap: () => context.go(catalogPath(toProducts: true)),
        ),
        SizedBox(height: desktop ? 72 : 32),
        ContentWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(eyebrow: 'ÚLTIMOS LANÇAMENTOS', title: 'Peças que acabaram\nde chegar'),
              SizedBox(height: desktop ? 40 : 24),
              if (catalog.loading && arrivals.isEmpty)
                const LoadingView()
              else if (arrivals.isEmpty)
                const EmptyState(icon: Icons.new_releases_outlined, title: 'Em breve novos lançamentos')
              else
                ProductCarousel(products: arrivals),
            ],
          ),
        ),
        if (spotlight != null) ...[SizedBox(height: desktop ? 72 : 36), _Spotlight(product: spotlight)],
        SizedBox(height: desktop ? 88 : 48),
        // Acima do rodapé: "Todas as peças. Um só estilo." → produtos do Catálogo.
        BannerImage(
          asset: NiceAssets.catalogCta,
          aspectRatio: 2880 / 960,
          label: 'Todas as peças. Um só estilo. Ver todos os produtos',
          onTap: () => context.go(catalogPath(toProducts: true)),
        ),
      ],
    );
  }
}

class _Spotlight extends StatelessWidget {
  const _Spotlight({required this.product});

  final Product product;

  /// Bloco "Em destaque": retângulo cinza-claro com a foto editorial à
  /// esquerda, texto no meio e, à direita, a foto do produto sobre um bloco
  /// vermelho e o kanji 東京.
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final desktop = context.isDesktop;
    final compact = context.isCompact;
    void open() => context.push('/produto/${product.id}');

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('EM DESTAQUE', style: text.labelMedium),
        const SizedBox(height: 10),
        Text(product.title.toUpperCase(), style: NiceTheme.spotlightTitle(large: !compact)),
        const SizedBox(height: 16),
        Text(product.description, style: text.bodyLarge),
        const SizedBox(height: 28),
        InkWell(
          onTap: open,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('VER DETALHES', style: NiceTheme.spacedLink()),
                const SizedBox(width: 18),
                const Icon(Icons.arrow_outward, size: 20, color: NiceTheme.brightRed),
              ],
            ),
          ),
        ),
      ],
    );

    const editorial = AspectRatio(
      aspectRatio: 826 / 679,
      child: Image(image: AssetImage(NiceAssets.newArrivalsSpotlight), fit: BoxFit.cover),
    );

    final productShot = AspectRatio(
      aspectRatio: 0.82,
      child: Stack(
        children: [
          // Bloco vermelho atrás da peça, deslocado para a direita.
          const Positioned(right: 0, top: 24, bottom: 24, width: 96, child: ColoredBox(color: NiceTheme.brightRed)),
          Positioned.fill(
            right: 28,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: open,
                child: NiceNetworkImage(url: product.imageUrl),
              ),
            ),
          ),
        ],
      ),
    );

    final kanji = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 1, height: 56, color: NiceTheme.charcoal),
        const SizedBox(height: 14),
        Text('東', style: NiceTheme.kanji()),
        Text('京', style: NiceTheme.kanji()),
        const SizedBox(height: 14),
        Container(width: 1, height: 56, color: NiceTheme.charcoal),
      ],
    );

    final Widget content;
    if (desktop) {
      content = Row(
        children: [
          const Expanded(flex: 9, child: editorial),
          const SizedBox(width: 40),
          Expanded(flex: 7, child: info),
          const SizedBox(width: 24),
          Expanded(flex: 5, child: productShot),
          SizedBox(width: 88, child: Center(child: kanji)),
        ],
      );
    } else if (!compact) {
      content = Row(
        children: [
          const Expanded(child: editorial),
          Expanded(
            child: Padding(padding: const EdgeInsets.all(32), child: info),
          ),
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          editorial,
          Padding(padding: const EdgeInsets.all(24), child: info),
        ],
      );
    }

    return ContentWrapper(
      child: ColoredBox(color: NiceTheme.sectionGray, child: content),
    );
  }
}
