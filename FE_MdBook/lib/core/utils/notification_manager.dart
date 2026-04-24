import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  static NotificationManager get instance => _instance;
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final ValueNotifier<List<AppNotification>> notifications = ValueNotifier([]);
  final ValueNotifier<int> unreadCount = ValueNotifier(0);

  Future<void> init() async {
    await loadNotifications();
  }

  Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('app_notifications');
    if (data != null) {
      final List<dynamic> list = jsonDecode(data);
      notifications.value = list.map((e) => AppNotification.fromJson(e)).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _updateUnreadCount();
    }
  }

  Future<void> addNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    final newNotif = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
    );

    notifications.value = [newNotif, ...notifications.value];
    _updateUnreadCount();
    await _saveToPrefs();
  }

  void markAsRead(String id) {
    final index = notifications.value.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications.value[index].isRead = true;
      notifications.value = List.from(notifications.value);
      _updateUnreadCount();
      _saveToPrefs();
    }
  }

  void markAllAsRead() {
    for (var n in notifications.value) {
      n.isRead = true;
    }
    notifications.value = List.from(notifications.value);
    unreadCount.value = 0;
    _saveToPrefs();
  }

  void clearAll() {
    notifications.value = [];
    unreadCount.value = 0;
    _saveToPrefs();
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.value.where((n) => !n.isRead).length;
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(notifications.value.map((e) => e.toJson()).toList());
    await prefs.setString('app_notifications', data);
  }

  // Beautiful Popup Logic
  void showPopup(BuildContext context, {required String title, required String body, required String type}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _BeautifulNotificationPopup(
        title: title,
        body: body,
        type: type,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
    
    // Auto remove after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }
}

class _BeautifulNotificationPopup extends StatefulWidget {
  final String title;
  final String body;
  final String type;
  final VoidCallback onDismiss;

  const _BeautifulNotificationPopup({
    required this.title,
    required this.body,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_BeautifulNotificationPopup> createState() => _BeautifulNotificationPopupState();
}

class _BeautifulNotificationPopupState extends State<_BeautifulNotificationPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color mainColor;
    IconData icon;

    switch (widget.type) {
      case 'booking':
        mainColor = const Color(0xFF38A3A5);
        icon = Icons.calendar_today_rounded;
        break;
      case 'confirm':
        mainColor = const Color(0xFF4CAF50);
        icon = Icons.check_circle_rounded;
        break;
      case 'cancel':
        mainColor = const Color(0xFFE53935);
        icon = Icons.cancel_rounded;
        break;
      default:
        mainColor = const Color(0xFF2196F3);
        icon = Icons.notifications_rounded;
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _offsetAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: mainColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: mainColor.withOpacity(0.2), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: mainColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: mainColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.body,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                    onPressed: widget.onDismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
