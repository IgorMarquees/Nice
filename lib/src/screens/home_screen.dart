import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/assets.dart';
import '../controllers/auth_controller.dart';
import '../controllers/catalog_controller.dart';
import '../theme/nice_theme.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/category_section.dart';
import '../widgets/hero_banner.dart';
import '../widgets/product_grid.dart';
import '../widgets/responsive.dart';
import '../widgets/section_header.dart';
import '../widgets/state_views.dart';

const _slides = [
  BannerSlide(
    image: NiceAssets.heroBeyond,
    eyebrow: 'NICE / Streetwear by Japan',
    title: 'Beyond',
    accent: 'the streets.',
    subtitle: 'Mais que roupas, é uma forma de ver o mundo.',
    ctaLabel: 'Explore a coleção',
    route: '/catalogo',
  ),
  BannerSlide(
    image: NiceAssets.heroCulture,
    eyebrow: 'NICE / Streetwear by Japan',
    title: 'Cultura em',
    accent: 'movimento.',
    subtitle: 'Rua, atitude e autenticidade em cada detalhe.',
    ctaLabel: 'Ver novidades',
    route: '/novidades',
  ),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final desktop = context.isDesktop;
    final featured = catalog.featured.take(desktop ? 8 : 6).toList();
    final arrivals = catalog.newArrivals.take(4).toList();
    final gap = SizedBox(height: desktop ? 72 : 36);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (context.isCompact) const _MobileGreeting(),
        const BannerCarousel(slides: _slides),
        if (context.isCompact) ...[
          const SizedBox(height: 20),
          const ContentWrapper(child: CategorySection()),
        ],
        gap,
        if (!context.isCompact) ...[
          HeroBanner(
            image: NiceAssets.identity,
            eyebrow: 'Identidade',
            title: 'A essência',
            accent: 'da NICE.',
            subtitle: 'Do Japão para o mundo. Streetwear que conecta pessoas, ideias e identidades.',
            ctaLabel: 'Conheça a NICE',
            onCta: () => context.go('/sobre'),
            large: false,
            height: 360,
          ),
          gap,
        ],
        ContentWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                eyebrow: 'Destaques',
                title: 'Escolhas do momento',
                onAction: () => context.go('/catalogo'),
              ),
              const SizedBox(height: 24),
              if (catalog.loading && featured.isEmpty)
                const LoadingView()
              else
                ProductGrid(products: featured),
            ],
          ),
        ),
        if (!context.isCompact) ...[
          gap,
          ContentWrapper(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(eyebrow: 'Categorias', title: 'Explore por estilo'),
                const SizedBox(height: 24),
                const CategorySection(),
              ],
            ),
          ),
        ],
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
              const SizedBox(height: 24),
              ProductGrid(products: arrivals),
            ],
          ),
        ),
        gap,
        if (!context.isCompact)
          HeroBanner(
            image: NiceAssets.cta,
            eyebrow: 'NICE / Completo',
            title: 'Todas as peças.',
            accent: 'Um só estilo.',
            subtitle: 'Explore o catálogo completo da NICE e encontre o que combina com você.',
            ctaLabel: 'Ver todos os produtos',
            onCta: () => context.go('/catalogo'),
            large: false,
            height: 380,
          ),
        if (context.isCompact) const SizedBox(height: 40),
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
