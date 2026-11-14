import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/assets.dart';
import '../controllers/catalog_controller.dart';
import '../models/product.dart';
import '../theme/nice_theme.dart';
import '../widgets/hero_banner.dart';
import '../widgets/nice_network_image.dart';
import '../widgets/product_grid.dart';
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
        HeroBanner(
          image: NiceAssets.newArrivals,
          eyebrow: 'NICE® / Latest drop',
          title: 'Just',
          accent: 'dropped.',
          subtitle: 'Novas peças. Nova atitude. Descubra as últimas novidades da NICE.',
          ctaLabel: 'Ver todos os lançamentos',
          onCta: () => context.go('/catalogo'),
          height: desktop ? 480 : 300,
        ),
        SizedBox(height: desktop ? 64 : 32),
        ContentWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(eyebrow: 'Últimos lançamentos', title: 'Peças que acabaram de chegar'),
              const SizedBox(height: 24),
              if (catalog.loading && arrivals.isEmpty)
                const LoadingView()
              else if (arrivals.isEmpty)
                const EmptyState(icon: Icons.new_releases_outlined, title: 'Em breve novos lançamentos')
              else
                ProductGrid(products: arrivals, maxColumns: 3),
            ],
          ),
        ),
        if (spotlight != null) ...[
          SizedBox(height: desktop ? 72 : 36),
          _Spotlight(product: spotlight),
        ],
        const SizedBox(height: 48),
      ],
    );
  }
}

class _Spotlight extends StatelessWidget {
  const _Spotlight({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final desktop = context.isDesktop;

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('EM DESTAQUE', style: text.labelMedium),
        const SizedBox(height: 10),
        Text(product.title.toUpperCase(), style: desktop ? text.displaySmall : text.headlineMedium),
        const SizedBox(height: 12),
        Text(product.description, style: text.bodyLarge),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => context.push('/produto/${product.id}'),
          icon: const Icon(Icons.arrow_outward, size: 18),
          label: const Text('VER DETALHES'),
        ),
      ],
    );

    final image = AspectRatio(
      aspectRatio: 1.3,
      child: ColoredBox(
        color: NiceTheme.softGray,
        child: NiceNetworkImage(url: product.imageUrl),
      ),
    );

    return ContentWrapper(
      child: desktop
          ? Row(
              children: [
                Expanded(child: info),
                const SizedBox(width: 48),
                Expanded(child: image),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [image, const SizedBox(height: 20), info],
            ),
    );
  }
}
