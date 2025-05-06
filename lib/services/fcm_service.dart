// lib/services/fcm_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// Глобальный ключ навигации для пушей
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class FCMService {
  static final _messaging          = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'orders',
    'Order Notifications',
    description: 'Уведомления о готовности заказа',
    importance: Importance.high,
  );

  /// Инициализация FCM и локальных уведомлений
  static Future<void> init() async {
    // Запрос разрешений (особенно для iOS)
    await _messaging.requestPermission();

    // Настройка flutter_local_notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS:    DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse resp) {
        final orderId = resp.payload;
        if (orderId != null) {
          navigatorKey.currentState
              ?.pushNamed('/orderDetails', arguments: orderId);
        }
      },
    );

    // Создание канала для Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Обработка пушей в foreground
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

    // Обработка клика по пушу, когда приложение в фоне
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      final orderId = msg.data['orderId'];
      if (orderId != null) {
        navigatorKey.currentState
            ?.pushNamed('/orderDetails', arguments: orderId);
      }
    });
  }

  /// Получить текущий FCM-токен
  static Future<String?> getToken() => _messaging.getToken();

  /// Сохранить токен в Firestore: users/{uid}.fcmToken
  static Future<void> saveTokenToFirestore(String uid) async {
    final token = await getToken();
    if (token == null) return;
    final doc = FirebaseFirestore.instance.collection('users').doc(uid);
    await doc.set({
      'fcmToken':     token,
      'tokenUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      doc.update({
        'fcmToken':     newToken,
        'tokenUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Удалить токен из Firestore
  static Future<void> deleteToken(String uid) async {
    final doc = FirebaseFirestore.instance.collection('users').doc(uid);
    await doc.update({
      'fcmToken':     FieldValue.delete(),
      'tokenUpdated': FieldValue.delete(),
    });
  }
}
