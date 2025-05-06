// lib/services/fcm_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Ключ для навигации из пуш-уведомлений
final navigatorKey = GlobalKey<NavigatorState>();

class FCMService {
  static final _messaging = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  // android-канал (mobile-only)
  static const _channel = AndroidNotificationChannel(
    'orders',
    'Order Notifications',
    importance: Importance.high,
    description: 'Уведомления о готовности заказа',
  );

  /// Вызываем в main() ДО runApp()
  static Future<void> init() async {
    await _messaging.requestPermission();

    // локальные уведомления нужны только на мобильных
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
            navigatorKey.currentState
                ?.pushNamed('/orderDetails', arguments: orderId);
          }
        },
      );
      await _local
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    // foreground-push
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

    // push при открытом / фоне
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final orderId = msg.data['orderId'];
      if (orderId != null) {
        navigatorKey.currentState
            ?.pushNamed('/orderDetails', arguments: orderId);
      }
    });
  }

  /// —--- helpers для Firestore ---—
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
