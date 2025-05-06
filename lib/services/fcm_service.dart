// lib/services/fcm_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// Глобальный ключ для навигации из уведомлений
final navigatorKey = GlobalKey<NavigatorState>();

/// Сервис по работе с FCM и локальными уведомлениями
class FCMService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'orders',                   // id канала
    'Order Notifications',      // название канала
    description: 'Уведомления о готовности заказа',
    importance: Importance.high,
  );

  /// Инициализация FCM и локальных уведомлений.
  /// Вызывать в main() **до** runApp().
  static Future<void> init() async {
    // 1. Запрос разрешений (особенно для iOS)
    await _messaging.requestPermission();

    // 2. Настройка плагина flutter_local_notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse resp) {
        navigatorKey.currentState?.pushNamed('/orders');
      },
    );

    // 3. Создаём канал для Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 4. Обработчик приходящих push в foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      final n = msg.notification;
      if (n == null) return;

      _localNotifications.show(
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
    });
  }

  /// Получить текущий FCM-токен
  static Future<String?> getToken() => _messaging.getToken();
}

/// Хелпер для записи FCM-токена в Firestore
class FcmTokenHelper {
  /// Читает текущий FCM-токен и сохраняет его в users/{uid}.fcmToken
  static Future<void> saveTokenToFirestore(String uid) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    await userDoc.set({
      'fcmToken':     token,
      'tokenUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Подписываемся на обновления токена
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      userDoc.update({
        'fcmToken':     newToken,
        'tokenUpdated': FieldValue.serverTimestamp(),
      });
    });
  }
}
