import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Универсально показывает сеть/asset-картинку.
/// На Web — Image.network, на остальных платформах — CachedNetworkImage.
/// Если [url] пустой или упала загрузка → placeholder.
class UniversalImage extends StatelessWidget {
  const UniversalImage(
      this.url, {
        super.key,
        this.width,
        this.height,
        this.fit = BoxFit.cover,
        this.borderRadius = 0,
      });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final placeholder = Image.asset(
      'assets/placeholder.png',
      width: width,
      height: height,
      fit: fit,
    );

    Widget child;
    if (url.isEmpty) {
      child = placeholder;
    } else if (kIsWeb) {
      child = Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder,
      );
    } else {
      child = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      );
    }

    return borderRadius == 0
        ? child
        : ClipRRect(borderRadius: BorderRadius.circular(borderRadius), child: child);
  }
}
