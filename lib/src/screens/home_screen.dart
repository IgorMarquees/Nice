import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/assets.dart';
import '../controllers/auth_controller.dart';
import '../controllers/catalog_controller.dart';
import '../theme/nice_theme.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/banner_image.dart';
import '../widgets/category_section.dart';
import '../widgets/product_carousel.dart';
import '../widgets/product_grid.dart';
import '../widgets/responsive.dart';
import '../widgets/section_header.dart';
import '../widgets/state_views.dart';

const _slides = [
  BannerSlide(
    image: NiceAssets.homeHero1,
    aspectRatio: 2880 / 1500,
    route: '/catalogo',
    label: 'Beyond the streets. Explore a coleção',
  ),
  BannerSlide(
    image: NiceAssets.homeHero2,
    aspectRatio: 2880 / 1500,
    route: '/catalogo',
    label: 'Cultura em movimento. Explore a coleção',
  ),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final desktop = context.isDesktop;
    final compact = context.isCompact;
    final featured = catalog.featured.take(desktop ? 6 : 4).toList();
    final arrivals = catalog.newArrivals.take(9).toList();
    final gap = SizedBox(height: desktop ? 88 : 40);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compact) const _MobileGreeting(),
        const BannerCarousel(slides: _slides),
        if (compact) ...[
          const SizedBox(height: 20),
          const ContentWrapper(child: CategorySection()),
        ],
        SizedBox(height: desktop ? 56 : 28),
        BannerImage(
          asset: NiceAssets.homeEssence,
          aspectRatio: 2880 / 800,
          label: 'A essência da NICE. Conheça a NICE',
          onTap: () => context.go('/sobre'),
        ),
        gap,
        ContentWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                eyebrow: 'Destaques',
                title: 'Escolhas do momento',
                onAction: () => context.go('/catalogo'),
              ),
              SizedBox(height: desktop ? 40 : 24),
              if (catalog.loading && featured.isEmpty)
                const LoadingView()
              else
                ProductGrid(products: featured, maxColumns: 3),
            ],
          ),
        ),
        gap,
        ContentWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                eyebrow: 'Novidades',
                title: 'Acabou de chegar',
                onAction: () => context.go('/novidades'),
              ),
              SizedBox(height: desktop ? 40 : 24),
              ProductCarousel(products: arrivals),
            ],
          ),
        ),
        gap,
        if (!compact) const _CategoriesBand() else const SizedBox(height: 16),
      ],
    );
  }
}

/// "Categorias / Explore por estilo" em fundo claro, que escurece até o
/// rodapé (na Web).
class _CategoriesBand extends StatelessWidget {
  const _CategoriesBand();

  @override
  Widget build(BuildContext context) {
    final desktop = context.isDesktop;
    const header = SectionHeader(eyebrow: 'Categorias', title: 'Explore\npor estilo');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColoredBox(
          color: NiceTheme.sectionGray,
          child: Padding(
            padding: EdgeInsets.only(top: desktop ? 72 : 48, bottom: kIsWeb ? 0 : 48),
            child: ContentWrapper(
              child: desktop
                  ? const Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: 280, child: header),
                        SizedBox(width: 32),
                        Expanded(child: CategorySection()),
                      ],
                    )
                  : const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [header, SizedBox(height: 24), CategorySection()],
                    ),
            ),
          ),
        ),
        if (kIsWeb)
          const SizedBox(
            height: 160,
            child: DecoratedBox(decoration: BoxDecoration(gradient: NiceTheme.footerFade)),
          ),
      ],
    );
  }
}

class _MobileGreeting extends StatelessWidget {
  const _MobileGreeting();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final text = Theme.of(context).textTheme;
    final name = auth.user?.name.split(' ').first;

    return Padding(
      padding: EdgeInsets.fromLTRB(context.pagePadding, 4, context.pagePadding, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name == null ? 'Bem-vindo à NICE' : 'Bem-vindo, $name', style: text.headlineSmall),
          const SizedBox(height: 14),
          TextField(
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              final query = value.trim();
              context.go(query.isEmpty ? '/catalogo' : '/catalogo?busca=${Uri.encodeQueryComponent(query)}');
            },
            decoration: const InputDecoration(
              hintText: 'Encontre seu drip...',
              prefixIcon: Icon(Icons.search, color: NiceTheme.red),
            ),
          ),
        ],
      ),
    );
  }
}
