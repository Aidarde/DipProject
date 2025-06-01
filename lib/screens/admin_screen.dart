// lib/screens/admin_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/universal_image.dart';
import '../l10n/l10n_ext.dart';

const kStatuses = <String>[
  'ожидается',
  'в обработке',
  'готов',
  'выдан',
];

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  /// выбранный фильтр статуса (по-умолчанию «все»)
  String _statusFilter = 'все';

  Color _statusColor(String s) {
    switch (s) {
      case 'ожидается':
        return Colors.grey;
      case 'в обработке':
        return Colors.orange;
      case 'готов':
        return Colors.green;
      case 'выдан':
        return Colors.blue;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n      = context.l10n;
    final userProv  = context.watch<UserProvider>();
    final themeProv = context.watch<ThemeProvider>();
    final localeProv = context.watch<LocaleProvider>();

    // 1. ожидание загрузки профиля
    if (userProv.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = userProv.user;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text(l10n.userNotFound)),
      );
    }

    // 2. проверка филиала
    final branchName = (user.branchName ?? '').trim();
    if (branchName.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(l10n, themeProv, localeProv),
        body: Center(child: Text(l10n.noBranchAssigned)),
      );
    }

    // 3. стрим заказов конкретного филиала
    final ordersStream = FirebaseFirestore.instance
        .collection('orders')
        .where('branchName', isEqualTo: branchName)
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      appBar: _buildAppBar(l10n, themeProv, localeProv),
      body: Column(
        children: [
          // ── инфо-полоса + фильтр ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    l10n.branch(branchName),
                    style: AppStyles.sectionTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                Text(l10n.filter),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _statusFilter,
                  underline: const SizedBox(),
                  items: [
                    DropdownMenuItem(value: 'все', child: Text(l10n.all)),
                    ...kStatuses.map((s) {
                      final txt = _localizedStatus(l10n, s);
                      return DropdownMenuItem(value: s, child: Text(txt));
                    }),
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v ?? 'все'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // ── список заказов ─────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: ordersStream,
              builder: (ctx, snap) {
                if (snap.hasError) {
                  return Center(child: Text(l10n.errorLoading('${snap.error}')));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs.where((d) {
                  final s = (d['status'] ?? '').toString().toLowerCase();
                  return _statusFilter == 'все' || s == _statusFilter;
                }).toList();

                if (docs.isEmpty) {
                  return Center(child: Text(l10n.noOrdersForFilter));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data   = docs[i].data();
                    final id     = docs[i].id;
                    final status = (data['status'] as String?)?.toLowerCase() ?? '';
                    final total  = (data['total'] as num?)?.round() ?? 0;
                    final ts     = (data['timestamp'] as Timestamp?)?.toDate();
                    final items  = List<Map<String, dynamic>>.from(data['items'] ?? []);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        title: Text(l10n.order(id)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.amount(total)),
                            Text(
                              l10n.status(_localizedStatus(l10n, status)),
                              style: TextStyle(color: _statusColor(status)),
                            ),
                            if (ts != null)
                              Text(l10n.date(
                                  '${ts.day.toString().padLeft(2, '0')}.${ts.month.toString().padLeft(2, '0')}.${ts.year} '
                                      '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}')),
                          ],
                        ),
                        children: [
                          ...items.map((it) {
                            final url   = it['image'] as String? ?? '';
                            final name  = it['name']  as String? ?? '-';
                            final price = (it['price'] as num?)?.round() ?? 0;

                            final img = url.startsWith('http')
                                ? UniversalImage(url, width: 56, height: 56, borderRadius: 8)
                                : Image.asset(url, width: 40, height: 40, fit: BoxFit.cover);

                            return ListTile(
                              leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: img),
                              title: Text(name),
                              trailing: Text('$price ${l10n.som}'),
                            );
                          }),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Text(l10n.changeStatus),
                                const SizedBox(width: 12),
                                DropdownButton<String>(
                                  value: status,
                                  items: kStatuses.map((s) {
                                    return DropdownMenuItem(
                                      value: s,
                                      child: Text(_localizedStatus(l10n, s)),
                                    );
                                  }).toList(),
                                  onChanged: (newStatus) {
                                    if (newStatus != null) {
                                      FirebaseFirestore.instance
                                          .collection('orders')
                                          .doc(id)
                                          .update({'status': newStatus});
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Строка-перевод для статуса
  String _localizedStatus(AppLocalizations l10n, String s) {
    switch (s) {
      case 'ожидается':
        return l10n.pending;
      case 'в обработке':
        return l10n.inProcess;
      case 'готов':
        return l10n.ready;
      case 'выдан':
        return l10n.delivered;
      default:
        return s;
    }
  }

  /// Общий AppBar с выходом / тема / язык
  AppBar _buildAppBar(
      AppLocalizations l10n, ThemeProvider themeProv, LocaleProvider localeProv) {
    return AppBar(
      title: Text('Панель администратора', style: AppStyles.appBarTitle),
      backgroundColor: AppColors.red,
      actions: [
        PopupMenuButton<String>(
          onSelected: (val) async {
            switch (val) {
              case 'theme':
                themeProv.toggleTheme();
                break;
              case 'lang':
                final isRu = localeProv.locale.languageCode == 'ru';
                localeProv.setLocale(Locale(isRu ? 'ky' : 'ru'));
                break;
              case 'logout':
                await AuthService.signOut();
                break;
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'theme',
              child: Row(
                children: [
                  Icon(themeProv.themeMode == ThemeMode.dark
                           ? Icons.light_mode
                           : Icons.dark_mode),
                  const SizedBox(width: 8),
                  Text(themeProv.themeMode == ThemeMode.dark ? 'Light' : 'Dark'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'lang',
              child: Row(
                children: [
                  const Icon(Icons.language),
                  const SizedBox(width: 8),
                  Text(localeProv.locale.languageCode == 'ru' ? 'Кыргызча' : 'Русский'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.logout),
                  const SizedBox(width: 8),
                  Text(l10n.logout),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
