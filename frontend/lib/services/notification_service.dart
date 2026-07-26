import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/queue_model.dart';
import '../screens/main_screen.dart';
import '../screens/notification_screen.dart';
import 'firebase_service.dart';

class AppNotification {
  final String id;
  final String message;
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FirebaseService _firebaseService = FirebaseService();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Map<String, String> _previousQueueStatuses = {};
  bool _isInitialized = false;

  void init() {
    if (_isInitialized) return;
    _isInitialized = true;

    _firebaseService.activeQueuesStream.listen((queues) {
      for (var q in queues) {
        final prevStatus = _previousQueueStatuses[q.id];
        
        // Detect state change to SELESAI for Booth queues
        if (q.type == 'Booth' && q.status == 'SELESAI' && prevStatus != 'SELESAI') {
          // If prevStatus is null, it means it's the first time we see this queue.
          // To prevent firing notifications for old completed queues on app start,
          // we only trigger if prevStatus was something else (e.g. 'MENUNGGU').
          if (prevStatus != null) {
            _handleQueueCompleted(q);
          }
        }
        
        // Update previous status
        _previousQueueStatuses[q.id] = q.status;
      }
    });
  }

  void _handleQueueCompleted(QueueModel q) async {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: 'Sesi foto ${q.name} telah selesai!',
      timestamp: DateTime.now(),
    );

    _notifications.insert(0, notification);
    notifyListeners();

    // Play sound
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      debugPrint('Error playing notification sound: $e');
    }

    // Show custom top toast with bounce animation
    _showTopNotification(q);
  }

  OverlayEntry? _currentOverlay;

  void _showTopNotification(QueueModel q) {
    if (_currentOverlay != null) {
      _currentOverlay?.remove();
      _currentOverlay = null;
    }

    _currentOverlay = OverlayEntry(
      builder: (context) => _TopBounceNotification(
        queueName: q.name,
        onDismiss: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
        },
      ),
    );

    navigatorKey.currentState?.overlay?.insert(_currentOverlay!);
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    bool changed = false;
    for (var n in _notifications) {
      if (!n.isRead) {
        n.isRead = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }
}

class _TopBounceNotification extends StatefulWidget {
  final String queueName;
  final VoidCallback onDismiss;

  const _TopBounceNotification({
    Key? key,
    required this.queueName,
    required this.onDismiss,
  }) : super(key: key);

  @override
  __TopBounceNotificationState createState() => __TopBounceNotificationState();
}

class __TopBounceNotificationState extends State<_TopBounceNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0), // Start from above the screen
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.bounceOut,
      reverseCurve: Curves.easeIn,
    ));

    _controller.forward();

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          widget.onDismiss();
          Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
        },
        child: Dismissible(
          key: UniqueKey(),
          direction: DismissDirection.horizontal,
          onDismissed: (direction) {
            widget.onDismiss();
          },
          child: Material(
            color: Colors.transparent,
            child: SlideTransition(
              position: _offsetAnimation,
              child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xE6E2E8F0), // abu-abu transparent
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFFAC282C)), // Tema aplikasi
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'Sesi foto ',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black, // teks hitam
                      ),
                      children: [
                        TextSpan(
                          text: widget.queueName,
                          style: const TextStyle(fontWeight: FontWeight.bold), // nama bold
                        ),
                        const TextSpan(text: ' telah selesai!'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
      ),
    );
  }
}
