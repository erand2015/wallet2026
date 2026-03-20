// lib/services/notification_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../theme/theme.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  int _notificationCounter = 0;
  final List<Map<String, dynamic>> _notificationHistory = [];

  // Kanalet e notifikimeve për Android
  static const String _channelId = 'warthog_transactions';
  static const String _channelName = 'Warthog Transactions';
  static const String _channelDescription = 'Notifications for WART transactions';

  // Stream për notifikime të reja
  final _notificationStream = StreamController<bool>.broadcast();
  Stream<bool> get notificationStream => _notificationStream.stream;

  // Getter për historik
  List<Map<String, dynamic>> get notificationHistory => _notificationHistory;

  // Inicializimi
  Future<void> init() async {
    if (_isInitialized) return;

    // Inicializo timezone
    tz.initializeTimeZones();

    // Konfigurimi për Android
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Konfigurimi për iOS
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Konfigurimi i përgjithshëm
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    // Inicializo plugin-in
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Krijo kanalin e notifikimeve për Android
    await _createNotificationChannel();
    
    // Kërko leje për iOS dhe Android
    await _requestPermissions();
    
    _isInitialized = true;
    print('✅ Notification service initialized');
  }

  // Krijimi i kanalit të notifikimeve për Android - VERSIONI I SAKTË
  Future<void> _createNotificationChannel() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );
      
      await androidPlugin.createNotificationChannel(channel);
      print('✅ Android notification channel created');
    }
  }

  // Kërko leje për notifikime
  Future<void> _requestPermissions() async {
    // Për iOS
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    
    // Për Android 13+
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  // Kur përdoruesi klikon njoftimin
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    
    final index = _notificationHistory.indexWhere(
      (n) => n['payload'] == response.payload && n['read'] == false
    );
    if (index != -1) {
      _notificationHistory[index]['read'] = true;
    }
    
    _checkUnreadNotifications();
  }

  void _checkUnreadNotifications() {
    final hasUnread = _notificationHistory.any((n) => n['read'] == false);
    _notificationStream.add(hasUnread);
  }

  // Shfaq njoftim - VERSIONI I SAKTË
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await init();

    _notificationCounter++;
    final id = _notificationCounter;

    // Detajet e notifikimit për Android - ME PARAMETRAT E SAKTË
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      color: WarthogColors.primaryOrange,
      ledColor: WarthogColors.primaryOrange,
      ledOnMs: 1000,
      ledOffMs: 500,
      fullScreenIntent: false,
      visibility: NotificationVisibility.public,
      ticker: 'Warthog Wallet',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    // Ruaj në historik
    _notificationHistory.add({
      'id': id,
      'title': title,
      'body': body,
      'payload': payload,
      'timestamp': DateTime.now(),
      'read': false,
    });

    _checkUnreadNotifications();
    print('✅ Notification shown: $title');
  }

  // Shfaq njoftim për transaksion
  Future<void> showTransactionNotification({
    required String txId,
    required double amount,
    required String type, // 'sent' ose 'received'
  }) async {
    String title = type == 'sent' ? '🚀 Transaction Sent' : '📥 Transaction Received';
    String body = type == 'sent'
        ? 'You sent $amount WART'
        : 'You received $amount WART';
    
    // Sigurohu që shërbimi është inicializuar
    if (!_isInitialized) await init();
    
    await showNotification(
      title: title,
      body: body,
      payload: txId,
    );
  }

  // Shfaq njoftim për konfirmim transaksioni
  Future<void> showTransactionConfirmedNotification(String txId) async {
    await showNotification(
      title: '✅ Transaction Confirmed',
      body: 'Your transaction has been confirmed on the blockchain',
      payload: txId,
    );
  }

  // Shfaq njoftim për gabim transaksioni
  Future<void> showTransactionErrorNotification(String error) async {
    await showNotification(
      title: '❌ Transaction Failed',
      body: 'Error: $error',
      payload: 'transaction_error',
    );
  }

  // Shfaq dialog me historik
  void showNotificationHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _notificationHistory.isEmpty
                    ? const Center(
                        child: Text(
                          'No notifications yet',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _notificationHistory.length,
                        separatorBuilder: (_, __) => const Divider(
                          color: Color(0xFF2A2A2A),
                        ),
                        itemBuilder: (context, index) {
                          final notif = _notificationHistory.reversed.toList()[index];
                          return ListTile(
                            leading: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: notif['read'] == false
                                    ? WarthogColors.primaryOrange
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(
                              notif['title'],
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: notif['read'] == false
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              notif['body'],
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: Text(
                              _formatTime(notif['timestamp']),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      for (var notif in _notificationHistory) {
        notif['read'] = true;
      }
      _checkUnreadNotifications();
    });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Anulo të gjitha njoftimet
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
    _notificationHistory.clear();
    _checkUnreadNotifications();
  }
}