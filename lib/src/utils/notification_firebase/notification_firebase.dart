import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:project_management/src/notifications/notifications.dart';
import 'package:project_management/src/services/api_service.dart';

import 'package:project_management/src/services/constants/api_constants.dart';
import 'package:project_management/src/utils/img.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationFirebaseService {
  static final NotificationFirebaseService _instance =
      NotificationFirebaseService._internal();
  factory NotificationFirebaseService() => _instance;
  NotificationFirebaseService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  OverlayEntry? _overlayEntry;
  GlobalKey<NavigatorState>? _navigatorKey;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  Future<void> initialize() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _requestPermission();
    await _getToken();
    _setupListeners();
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('✅ Notification permission: ${settings.authorizationStatus}');
  }

  Future<void> _getToken() async {
    SharedPreferences customPrefs = await SharedPreferences.getInstance();
    final user= await customPrefs.getString('id');
    print("user id----777777 : $user");
    final token = await _messaging.getToken();
    print('✅ FCM Token-----: $token');

    if (token != null) {
      await sendFCMTokenToBackend(user,token);
    }

    _messaging.onTokenRefresh.listen((newToken) async {
      print('🔄 Token refreshed: $newToken');
      await sendFCMTokenToBackend(user,newToken);

    });
  }
  // void _setupListeners() {
  //   FirebaseMessaging.onMessage.listen(_handleMessage);
  //   FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  //   FirebaseMessaging.instance.getInitialMessage().then((message) {
  //     if (message != null) _handleMessage(message);
  //   });
  // }
  void _setupListeners() {
    // 1️⃣ Foreground message
    FirebaseMessaging.onMessage.listen((message) {
      _handleMessage(message);
    });

    // 2️⃣ Background tap
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("📌 Notification opened from background");
      _navigateToNotificationScreen(message);
    });

    // 3️⃣ Terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print("📌 Notification opened from terminated");
        _navigateToNotificationScreen(message);
      }
    });
  }

  void _handleMessage(RemoteMessage message) {
    print(
      '📩 Notification received: ${message.notification?.title} - ${message.notification?.body}',
    );
    _playNotificationSound();
    _showBanner(message);
    _navigateToNotificationScreen(message);
  }

  void _playNotificationSound() async {
    try {
      await _audioPlayer.play(
        AssetSource('audio/mixkit-kids-cartoon-close-bells-2256.wav'),
      );
    } catch (e) {
      print('❌ Error playing notification sound: $e');
    }
  }

  void _showBanner(RemoteMessage message) {
    if (_navigatorKey?.currentState == null) return;

    final overlay = _navigatorKey!.currentState!.overlay;
    if (overlay == null) return;

    _overlayEntry?.remove();

    final title = message.notification?.title ?? 'Project Management Tool';
    final body =
        message.notification?.body ??
        'Nikhil Has Assigned A New Task For You Today.';

    // stateful wrapper for expand/collapse
    _overlayEntry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          top: MediaQuery.of(ctx).padding.top + 10,
          left: 12,
          right: 12,
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.horizontal,
            onDismissed: (_) {
              _overlayEntry?.remove();
              _overlayEntry = null;
            },
            child: _NotificationCard(
              title: title,
              body: body,
              onClose: () {
                _overlayEntry?.remove();
                _overlayEntry = null;
              },
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);

    /// Auto-dismiss after 6s if still showing
    Future.delayed(const Duration(seconds: 6), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
    );
  }

  Future<void> sendFCMTokenToBackend(userId, String token) async {
    try {
      final body = {"user_id": userId, "fcm_token": token};
      print("🔥 FCM Request Body: $body");
      final response = await ApiService.post(ApiConstants.sendFcmToken,body);
      print("FCM SEND RESPONSE: $response");
    } catch (e) {
      print('❌ FCM Token API error: ${e.toString()}');
    }
  }

  void _navigateToNotificationScreen(RemoteMessage message) {
    try {
      if (_navigatorKey?.currentState == null) return;

      _navigatorKey!.currentState!.push(
        MaterialPageRoute(builder: (_) => const Notifications()),
      );
    } catch (e) {
      print("❌ Navigation error: $e");
    }
  }
}
/// Separate widget to handle expand/collapse state
class _NotificationCard extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onClose;

  const _NotificationCard({
    Key? key,
    required this.title,
    required this.body,
    required this.onClose,
  }) : super(key: key);

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(AppImages.aapPngLogo, width: 28, height: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: Colors.black,
                        ),
                      ),
                  
                      /// Body text
                      Text(
                        widget.body,
                        maxLines: _expanded ? 4 : 1,
                        overflow:
                            _expanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    setState(() {
                      _expanded = !_expanded;
                    });
                  },
                  child: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            /// Expanded actions
            if (_expanded) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      print("✅ Check tapped");
                      widget.onClose();
                    },
                    child: const Text(
                      "Check",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () {
                      print("⚙️ Settings tapped");
                      widget.onClose();
                    },
                    child: const Text(
                      "Settings",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
