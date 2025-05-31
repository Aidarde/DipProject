// lib/screens/home_screen.dart
import 'dart:developer' as dev;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';

import '../providers/branch_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/google_drive_link.dart';
import '../screens/menu_screen.dart';
import '../screens/cart_screen.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_styles.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Теперь используем тот же placeholder, что и в других местах
  static const _fallbackBanner = 'assets/placeholder.png';

  @override
  void initState() {
    super.initState();

    // Префетчим изображения популярных товаров
    FirebaseFirestore.instance
        .collection('menu')
        .where('popular', isEqualTo: true)
        .get()
        .then((snap) {
      for (var d in snap.docs) {
        final url = (d['image'] as String? ?? '').toDriveDirect();
        if (url.startsWith('http')) {
          precacheImage(CachedNetworkImageProvider(url), context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final branch = context.watch<BranchProvider>().selectedBranch ?? '';
    final cart   = context.read<CartProvider>();
    final theme  = Theme.of(context);
    final size   = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.red,
        title: Text(context.l10n.homeTab, style: AppStyles.appBarTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          const SizedBox(height: 12),

          // ── Баннеры ───────────────────────────────────────────────────────────
          SizedBox(
            height: 180,
            child: PageView.builder(
              controller: PageController(viewportFraction: .88),
              itemCount: 3,
              itemBuilder: (_, idx) {
                final name = 'assets/banners/promo${idx + 1}.png';
                return FutureBuilder<bool>(
                  future: _assetExists(name),
                  builder: (_, snap) {
                    final path = (snap.data == true) ? name : _fallbackBanner;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(path, fit: BoxFit.cover),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 28),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(context.l10n.popular, style: AppStyles.sectionTitle),
          ),
          const SizedBox(height: 12),

          // ── Популярные товары ────────────────────────────────────────────────
          SizedBox(
            height: 260,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('menu')
                  .where('popular', isEqualTo: true)
                  .snapshots(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      context.l10n.errorLoading('${snap.error}'),
                      style: AppStyles.errorText,
                    ),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      context.l10n.menuEmpty,
                      style: AppStyles.cardPrice,
                    ),
                  );
                }

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (_, i) {
                    final d      = docs[i].data();
                    final name   = d['name']      as String? ?? '';
                    final price  = (d['basePrice'] as num?)?.round() ?? 0;
                    final rawImg = d['image']     as String? ?? '';
                    final url    = rawImg.toDriveDirect();

                    return _PopularCard(
                      name     : name,
                      price    : price,
                      imageUrl : url,
                      width    : size.width * 0.42,
                      onAdd    : () {
                        cart.addItem(name: name, price: price, image: url);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.l10n.addedToCart(name))),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 36),

          // ── Кнопка «Смотреть всё меню» ───────────────────────────────────────
          Center(
            child: FilledButton.icon(
              icon : const Icon(Icons.restaurant_menu),
              label: Text(context.l10n.viewMenu, style: AppStyles.buttonText),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MenuScreen(branchName: branch)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Проверяем, существует ли файл в assets, чтобы не падать ошибкой.
  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      dev.log('Banner not found: $path');
      return false;
    }
  }
}

class _PopularCard extends StatelessWidget {
  final String name;
  final int    price;
  final String imageUrl;
  final double width;
  final VoidCallback onAdd;

  const _PopularCard({
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.onAdd,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme        = Theme.of(context);
    final surface      = theme.colorScheme.surface;
    final onSurface    = theme.colorScheme.onSurface;
    final subtitle     = theme.textTheme.bodyMedium?.copyWith(color: onSurface.withOpacity(.8));
    final isDark       = theme.brightness == Brightness.dark;
    final cardShadow   = isDark ? Colors.black.withOpacity(.2) : Colors.black26;

    return SizedBox(
      width: width,
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        shadowColor: cardShadow,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Изображение
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl    : imageUrl,
                placeholder : (_, __) => Image.asset(
                    'assets/placeholder.png',
                    width: 96, height: 96, fit: BoxFit.cover),
                errorWidget : (_, __, ___) => const Icon(Icons.broken_image, size: 96),
                width       : 96,
                height      : 96,
                fit         : BoxFit.cover,
              ),
            ),

            const SizedBox(height: 10),

            // Название
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),

            // Цена
            Text(
              '$price ${context.l10n.som}',
              style: subtitle?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.red,
              ),
            ),

            const SizedBox(height: 8),

            // Кнопка «Добавить»
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.red,
                minimumSize: const Size(44, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.zero,
              ),
              onPressed: onAdd,
              child: const Icon(Icons.add_shopping_cart, size: 20),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
