import 'dart:async';
import 'package:flutter/material.dart';

class NotificationOverlay {
  static final List<OverlayEntry> _activeNotifications = [];
  static const int _maxNotifications = 2;

  static void show(
      BuildContext context, {
        required String message,
        VoidCallback? onTap,
        Duration duration = const Duration(seconds: 4),
      }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlay = Overlay.of(context);
      if (overlay == null) return;

      late OverlayEntry overlayEntry;

      overlayEntry = OverlayEntry(
        builder: (context) {
          int index = _activeNotifications.indexOf(overlayEntry);
          double bottomOffset = 24.0 + (index * 70); // space between each notification

          return _BottomLeftNotification(
            message: message,
            bottomOffset: bottomOffset,
            onTap: onTap,
            onDismissed: () {
              if (overlayEntry.mounted) {
                overlayEntry.remove();
                _activeNotifications.remove(overlayEntry);
                _shiftNotifications();  // Shift notifications up after removal
              }
            },
          );
        },
      );

      // Insert the new notification
      _activeNotifications.add(overlayEntry);
      overlay.insert(overlayEntry);

      // If the number of active notifications exceeds the max limit, remove the oldest one
      if (_activeNotifications.length > _maxNotifications) {
        final oldestNotification = _activeNotifications.first;
        oldestNotification.remove();
        _activeNotifications.removeAt(0);
        _shiftNotifications();  // Shift notifications up after removal
      }

      // Auto-remove the notification after the specified duration
      Future.delayed(duration, () {
        if (overlayEntry.mounted) {
          overlayEntry.remove();
          _activeNotifications.remove(overlayEntry);
          _shiftNotifications();  // Shift notifications up after removal
        }
      });
    });
  }

  static void _shiftNotifications() {
    // After a notification is removed, we need to update the position of the remaining notifications
    for (int i = 0; i < _activeNotifications.length; i++) {
      double bottomOffset = 24.0 + (i * 70); // Adjust bottomOffset based on position
      _activeNotifications[i].markNeedsBuild();  // Rebuild each notification to update its position
    }
  }
}

class _BottomLeftNotification extends StatefulWidget {
  final String message;
  final double bottomOffset;
  final VoidCallback? onTap;
  final VoidCallback onDismissed;

  const _BottomLeftNotification({
    Key? key,
    required this.message,
    required this.bottomOffset,
    this.onTap,
    required this.onDismissed,
  }) : super(key: key);

  @override
  State<_BottomLeftNotification> createState() => _BottomLeftNotificationState();
}

class _BottomLeftNotificationState extends State<_BottomLeftNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    _controller.reverse().then((_) => widget.onDismissed());
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      bottom: widget.bottomOffset,
      child: SlideTransition(
        position: _offsetAnimation,
        child: GestureDetector(
          onTap: () {
            widget.onTap?.call();
            _close();
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 280,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(2, 2),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  GestureDetector(
                    onTap: _close,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, color: Colors.white, size: 18),
                    ),
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
