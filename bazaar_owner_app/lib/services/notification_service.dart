import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Enhanced Notification Service with Retry Logic, Timeout, and Better Error Handling
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // API Configuration
  static const String _apiUrl =
      'https://silly-klepon-809140.netlify.app/.netlify/functions/send-notification';

  // Retry & Timeout Configuration
  static const int _maxRetries = 3;
  static const Duration _timeout = Duration(seconds: 10);
  static const Duration _retryDelay = Duration(seconds: 2);

  bool _isInitialized = false;

  /// Initialize the notification service with robust error handling
  Future<void> initialize(String userId) async {
    if (_isInitialized) return;

    try {
      // 1. Request Permission
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('✅ Notification permission granted');

        // 2. Setup Local Notifications (for foreground)
        await _setupLocalNotifications();

        // 3. Get Token & Save with retry
        await _getAndSaveToken(userId);

        // 4. Listen for Token Refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          _saveTokenToFirestore(userId, newToken);
        });

        // 5. Foreground Message Handler
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // 6. Background Message Handler
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

        _isInitialized = true;
        debugPrint('✅ Notification service initialized successfully');
      } else {
        debugPrint('❌ Notification permission denied');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing notifications: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Get and save FCM token with retry logic
  Future<void> _getAndSaveToken(String userId) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final token = await _firebaseMessaging.getToken().timeout(_timeout);
        if (token != null) {
          await _saveTokenToFirestore(userId, token);
          return;
        }
      } catch (e) {
        debugPrint(
            '⚠️ Attempt $attempt/$_maxRetries failed to get FCM token: $e');
        if (attempt < _maxRetries) {
          await Future.delayed(_retryDelay * attempt);
        }
      }
    }
    debugPrint('❌ Failed to get FCM token after $_maxRetries attempts');
  }

  /// Save FCM token to Firestore with error handling
  Future<bool> _saveTokenToFirestore(String userId, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('fcm_tokens')
          .doc(token)
          .set({
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': Platform.operatingSystem,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ FCM Token saved successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
      return false;
    }
  }

  /// Setup local notifications with proper channel configuration
  Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create high importance channel for Android
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
        '📩 Foreground message received: ${message.notification?.title}');
    _showLocalNotification(message);
  }

  /// Handle message tap
  void _handleMessageTap(RemoteMessage message) {
    debugPrint('👆 Message tapped: ${message.data}');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('👆 Local notification tapped: ${response.payload}');
  }

  /// Show local notification with enhanced styling
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'إشعار جديد',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFD4A574),
          enableVibration: true,
          playSound: true,
          styleInformation: BigTextStyleInformation(
            notification.body ?? '',
            htmlFormatBigText: true,
            contentTitle: notification.title ?? 'إشعار جديد',
            htmlFormatContentTitle: true,
          ),
          ticker: 'ticker',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Send notification with retry logic and timeout
  Future<bool> sendNotification({
    required String targetUserId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final response = await http
            .post(
              Uri.parse(_apiUrl),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({
                'targetUserId': targetUserId,
                'title': title,
                'body': body,
                'data': data ?? {},
              }),
            )
            .timeout(_timeout);

        if (response.statusCode == 200) {
          debugPrint('✅ Notification sent successfully to $targetUserId');
          return true;
        } else if (response.statusCode >= 500) {
          debugPrint(
              '⚠️ Server error (${response.statusCode}), attempt $attempt/$_maxRetries');
        } else {
          debugPrint(
              '❌ Client error (${response.statusCode}): ${response.body}');
          return false;
        }
      } on TimeoutException {
        debugPrint('⏰ Request timeout, attempt $attempt/$_maxRetries');
      } on SocketException catch (e) {
        debugPrint('🌐 Network error: $e, attempt $attempt/$_maxRetries');
      } catch (e) {
        debugPrint('❌ Unexpected error: $e, attempt $attempt/$_maxRetries');
      }

      if (attempt < _maxRetries) {
        await Future.delayed(_retryDelay * attempt);
      }
    }

    debugPrint('❌ Failed to send notification after $_maxRetries attempts');
    return false;
  }

  /// Send batch notifications to multiple users
  Future<Map<String, bool>> sendBatchNotifications({
    required List<String> targetUserIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final results = <String, bool>{};

    const batchSize = 5;
    for (var i = 0; i < targetUserIds.length; i += batchSize) {
      final batch = targetUserIds.skip(i).take(batchSize);
      final futures = batch.map((userId) async {
        final success = await sendNotification(
          targetUserId: userId,
          title: title,
          body: body,
          data: data,
        );
        return MapEntry(userId, success);
      });

      final batchResults = await Future.wait(futures);
      results.addEntries(batchResults);
    }

    return results;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from topic: $e');
    }
  }
}
