import 'package:flutter/material.dart';

import '../theme/nice_theme.dart';

class NiceNetworkImage extends StatelessWidget {
  const NiceNetworkImage({super.key, required this.url, this.fit = BoxFit.contain});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const _Placeholder();
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const _Placeholder(),
      errorBuilder: (_, _, _) => const _Placeholder(),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: NiceTheme.softGray,
      child: Center(child: Icon(Icons.checkroom, size: 48, color: NiceTheme.textGray)),
    );
  }
}
