import 'package:flutter/material.dart';

class TopNotification {
  static OverlayEntry? _currentEntry;

  static void show({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    Color backgroundColor = Colors.black87,
    Color textColor = Colors.white,
    VoidCallback? onTap,
    bool dismissibleWithBack = true,
  }) {
    _currentEntry?.remove();

    final overlay = Overlay.of(context);

    _currentEntry = OverlayEntry(
      builder: (context) => _TopNotificationOverlay(
        message: message,
        backgroundColor: backgroundColor,
        textColor: textColor,
        duration: duration,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
        onTap: onTap,
        dismissibleWithBack: dismissibleWithBack,
      ),
    );

    overlay.insert(_currentEntry!);
  }

  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _TopNotificationOverlay extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Color textColor;
  final Duration duration;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;
  final bool dismissibleWithBack;

  const _TopNotificationOverlay({
    required this.message,
    required this.backgroundColor,
    required this.textColor,
    required this.duration,
    required this.onDismiss,
    this.onTap,
    this.dismissibleWithBack = true,
  });

  @override
  State<_TopNotificationOverlay> createState() => _TopNotificationOverlayState();
}

class _TopNotificationOverlayState extends State<_TopNotificationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _progressController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();
    _progressController.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _slideController.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  void _dismiss() {
    if (mounted) {
      _slideController.reverse().then((_) => widget.onDismiss());
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * 0.75;

    final notificationCard = SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onTap: () {
          widget.onTap?.call();
          _dismiss();
        },
        child: IntrinsicWidth(
          child: IntrinsicHeight(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(12),
                color: widget.backgroundColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        widget.message,
                        style: TextStyle(color: widget.textColor, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: 1.0 - _progressController.value,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.textColor.withOpacity(0.5),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final content = Stack(
      children: [
        // Tap outside to dismiss
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _dismiss,
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 0,
          right: 0,
          child: Center(child: notificationCard), // Center it horizontally
        ),
      ],
    );

    return widget.dismissibleWithBack
        ? WillPopScope(
      onWillPop: () async {
        _dismiss();
        return false;
      },
      child: content,
    )
        : content;
  }

  @override
  void dispose() {
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }
}
