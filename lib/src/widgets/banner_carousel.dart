import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/nice_theme.dart';
import 'hero_banner.dart';
import 'responsive.dart';

class BannerSlide {
  const BannerSlide({
    required this.image,
    required this.eyebrow,
    required this.title,
    required this.accent,
    required this.subtitle,
    required this.ctaLabel,
    required this.route,
  });

  final String image;
  final String eyebrow;
  final String title;
  final String accent;
  final String subtitle;
  final String ctaLabel;
  final String route;
}

/// Banners rotativos da Home (autoplay a cada 6s).
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key, required this.slides});

  final List<BannerSlide> slides;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!_controller.hasClients || widget.slides.length < 2) return;
      final next = (_page + 1) % widget.slides.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = context.isDesktop ? 600.0 : 380.0;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.slides.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) {
              final slide = widget.slides[index];
              return HeroBanner(
                image: slide.image,
                eyebrow: slide.eyebrow,
                title: slide.title,
                accent: slide.accent,
                subtitle: slide.subtitle,
                ctaLabel: slide.ctaLabel,
                onCta: () => context.go(slide.route),
                height: height,
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 32 : 14,
                    height: 3,
                    color: i == _page ? NiceTheme.brightRed : NiceTheme.midGray,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
