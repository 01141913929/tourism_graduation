import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Replace with your actual Netlify function URL
  static const String _apiUrl =
      'https://silly-klepon-809140.netlify.app/.netlify/functions/send-notification';

  bool _isInitialized = false;

  Future<void> initialize(String userId) async {
    if (_isInitialized) return;

    // 1. Request Permission
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');

      // 2. Setup Local Notifications (for foreground)
      await _setupLocalNotifications();

      // 3. Get Token & Save
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(userId, token);
      }

      // 4. Listen for Token Refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _saveTokenToFirestore(userId, newToken);
      });

      // 5. Foreground Message Handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });

      _isInitialized = true;
    }
  }

  Future<void> _saveTokenToFirestore(String userId, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('fcm_tokens')
          .doc(token) // Use token as doc ID to prevent duplicates
          .set({
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem,
      });
      debugPrint('FCM Token saved: $token');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }

  /// Trigger a notification to another user via our Serverless API
  Future<bool> sendNotification({
    required String targetUserId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'targetUserId': targetUserId,
          'title': title,
          'body': body,
          'data': data,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Notification sent successfully');
        return true;
      } else {
        debugPrint('Failed to send notification: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
      return false;
    }
  }
}
