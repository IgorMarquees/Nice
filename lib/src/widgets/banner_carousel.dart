import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/nice_theme.dart';
import 'banner_image.dart';

class BannerSlide {
  const BannerSlide({
    required this.image,
    required this.aspectRatio,
    required this.route,
    required this.label,
  });

  final String image;
  final double aspectRatio;
  final String route;
  final String label;
}

/// Banners rotativos da Home (autoplay a cada 6s). Cada banner é um link.
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
    final ratio = widget.slides.first.aspectRatio;

    return AspectRatio(
      aspectRatio: ratio,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.slides.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) {
              final slide = widget.slides[index];
              return BannerImage(
                asset: slide.image,
                aspectRatio: ratio,
                label: slide.label,
                onTap: () => context.go(slide.route),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.slides.length; i++)
                  GestureDetector(
                    onTap: () => _controller.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      width: i == _page ? 32 : 14,
                      height: 3,
                      color: i == _page ? NiceTheme.brightRed : NiceTheme.midGray,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
