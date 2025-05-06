// lib/utils/cache_image.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

Future<void> precacheNetworkImage(String url, BuildContext ctx) async {
  if (url.isEmpty || !url.startsWith('http')) return;
  await precacheImage(CachedNetworkImageProvider(url), ctx);
}
