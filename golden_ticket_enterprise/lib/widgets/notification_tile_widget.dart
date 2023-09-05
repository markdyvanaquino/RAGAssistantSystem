import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/notification.dart' as notifClass;
import 'package:golden_ticket_enterprise/models/string_utils.dart';
import 'package:golden_ticket_enterprise/models/time_utils.dart';

class NotificationTile extends StatelessWidget {
  final notifClass.Notification notification;
  final VoidCallback? onTap;
  final IconData icon;
  final Color iconColor;

  const NotificationTile({
    Key? key,
    required this.notification,
    this.onTap,
    this.icon = Icons.notifications,
    this.iconColor = Colors.black,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String formattedDate = TimeUtil.formatTimestamp(notification.createdAt);

    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: iconColor,
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(StringUtils.limitWithEllipsis(notification.message, 16)),
          const SizedBox(height: 4),
          Text(
            formattedDate,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!notification.isRead)
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}