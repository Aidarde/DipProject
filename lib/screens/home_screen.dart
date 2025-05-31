// lib/screens/home_screen.dart
import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import '../providers/branch_provider.dart';
import '../providers/cart_provider.dart';

import '../utils/google_drive_link.dart';
import '../utils/universal_image.dart';
import '../screens/menu_screen.dart';
import '../screens/cart_screen.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_styles.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState() => _HomeScreenState(); }

class _HomeScreenState extends State<HomeScreen> {
  static const _fallback = 'assets/placeholder.png';

  @override
  void initState() {
    super.initState();
    // предварительный кеш на мобильных
    if (!kIsWeb) {
      FirebaseFirestore.instance
          .collection('menu')
          .where('popular', isEqualTo: true)
          .get()
          .then((snap) {
        for (final d in snap.docs) {
          final url = (d['image'] as String? ?? '').toDriveDirect();
          UniversalImage(url, width: 1, height: 1); // lazy precache
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final branch = context.watch<BranchProvider>().selectedBranch ?? '';
    final cart   = context.read<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.red,
        title: Text(context.l10n.homeTab, style: AppStyles.appBarTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          const SizedBox(height: 12),

          // ── РЕСПОНСИВНЫЙ БАННЕР-CAROUSEL ────────────────────────────────────
          LayoutBuilder(
            builder: (_, c) {
              final bannerH = c.maxWidth < 640
                  ? 180.0
                  : (c.maxWidth / 2.8).clamp(200, 300).toDouble();
              return SizedBox(
                height: bannerH,
                child: PageView.builder(
                  controller: PageController(viewportFraction: .88),
                  itemCount: 3,
                  itemBuilder: (_, idx) {
                    final asset = 'assets/banners/promo${idx + 1}.png';
                    return FutureBuilder<bool>(
                      future: _assetExists(asset),
                      builder: (_, snap) {
                        final src = (snap.data == true) ? asset : _fallback;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(src, fit: BoxFit.cover),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(context.l10n.popular, style: AppStyles.sectionTitle),
          ),
          const SizedBox(height: 12),

          // ── ПОПУЛЯРНЫЕ ТОВАРЫ ────────────────────────────────────────────────
          SizedBox(
            height: 270,
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
                    child: Text(context.l10n.errorLoading('${snap.error}'),
                        style: AppStyles.errorText),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(child: Text(context.l10n.menuEmpty));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (_, i) {
                    final d      = docs[i].data();
                    final name   = d['name'] ?? '';
                    final price  = (d['basePrice'] as num?)?.round() ?? 0;
                    final rawImg = (d['image'] as String?) ?? '';
                    final url = rawImg.toDriveDirect();

                    return _PopularCard(
                      name     : name,
                      price    : price,
                      imageUrl : url,
                      width    : 220,            // ширина карточки одинакова на всех платформах
                      onAdd    : () {
                        cart.addItem(name: name, price: price, image: url);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(context.l10n.addedToCart(name))));
                      },
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 36),

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

  Future<bool> _assetExists(String p) async {
    try { await rootBundle.load(p); return true; } catch (_) { dev.log('no $p'); return false; }
  }
}

class _PopularCard extends StatelessWidget {
  const _PopularCard({
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.width,
    required this.onAdd,
  });

  final String name;
  final int    price;
  final String imageUrl;
  final double width;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final surface = theme.colorScheme.surface;

    return SizedBox(
      width: width,
      child: Material(
        color: surface,
        elevation: 3,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UniversalImage(imageUrl, width: 100, height: 100, borderRadius: 12), // ← NEW
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(name,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            Text('$price ${context.l10n.som}',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.red,
                padding: EdgeInsets.zero,
                minimumSize: const Size(42, 34),
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onAdd,
              child: const Icon(Icons.add_shopping_cart, size: 18),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
