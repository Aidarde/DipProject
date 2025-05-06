// lib/utils/network_image.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Возвращает виджет с кэшированием и placeholder’ом
Widget networkImage(String url, {
  double? width, double? height, BoxFit fit = BoxFit.cover,
}) {
  if (url.isEmpty) {
    return const Icon(Icons.broken_image, size: 48);
  }
  return CachedNetworkImage(
    imageUrl: url,
    width: width,
    height: height,
    fit: fit,
    placeholder: (_, __) => Container(
      width: width, height: height,
      color: Colors.grey.shade200,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    ),
    errorWidget: (_, __, ___) =>
    const Icon(Icons.broken_image, size: 48),
  );
}
