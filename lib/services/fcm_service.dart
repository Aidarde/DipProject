// lib/services/fcm_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  FCMService._();                    // приватный конструктор-заглушка
  static final _messaging = FirebaseMessaging.instance;
  static final _local     = FlutterLocalNotificationsPlugin();

  // Android-канал (используется только на мобильных)
  static const _channel = AndroidNotificationChannel(
    'orders',
    'Order Notifications',
    importance: Importance.high,
    description: 'Уведомления о готовности заказа',
  );

  /// Инициализация Firebase Messaging и локальных уведомлений.
  /// Вызывать **до** `runApp`, передавая `navigatorKey`
  /// из `main.dart`, чтобы не было дублирования ключей.
  static Future<void> init(GlobalKey<NavigatorState> navKey) async {
    // Сохраняем key для дальнейшей навигации из пушей
    _navKey = navKey;

    // Разрешения (на Web автоматически запрашиваются браузером)
    await _messaging.requestPermission();

    // Локальные уведомления нужны только на мобильных
    if (!kIsWeb) {
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _local.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (resp) {
          final orderId = resp.payload;
          if (orderId != null) {
            _navKey.currentState?.pushNamed('/orderDetails', arguments: orderId);
          }
        },
      );
      await _local
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    // Пуш в foreground
    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n == null) return;

      if (!kIsWeb) {
        _local.show(
          n.hashCode,
          n.title,
          n.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: msg.data['orderId'],
        );
      }
    });

    // Пуш при запуске из фона / клике на уведомлении
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final orderId = msg.data['orderId'];
      if (orderId != null) {
        _navKey.currentState?.pushNamed('/orderDetails', arguments: orderId);
      }
    });
  }

  // -----------------------------------------------------------
  // --------------------- helpers ------------------------------
  // -----------------------------------------------------------

  static late GlobalKey<NavigatorState> _navKey;

  static Future<String?> getToken() => _messaging.getToken();

  static Future<void> saveTokenToFirestore(String uid) async {
    final token = await getToken();
    if (token == null) return;
    final doc = FirebaseFirestore.instance.collection('users').doc(uid);
    await doc.set({
      'fcmToken': token,
      'tokenUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _messaging.onTokenRefresh.listen((newTok) {
      doc.update({
        'fcmToken': newTok,
        'tokenUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> deleteToken(String uid) async =>
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
        'tokenUpdated': FieldValue.delete(),
      });
}
