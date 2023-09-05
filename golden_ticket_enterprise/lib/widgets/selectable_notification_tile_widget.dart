import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/notification.dart' as notifClass;
import 'package:golden_ticket_enterprise/models/time_utils.dart';

class SelectableNotificationTile extends StatelessWidget {
  final notifClass.Notification notification;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const SelectableNotificationTile({
    Key? key,
    required this.notification,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String formattedDate = TimeUtil.formatTimestamp(notification.createdAt);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: notification.isRead ? Colors.transparent : Colors.red,  // Red line if unread
            width: 5, // Adjust the width of the red line
          ),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: selectionMode
            ? Checkbox(
          value: isSelected,
          onChanged: (_) => onTap(),
        )
            : Icon(Icons.notifications),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.message != null) Text(notification.message!),
            SizedBox(height: 4),
            Text(
              formattedDate,
              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? Icon(Icons.circle, color: Colors.redAccent, size: 10)
            : null,
      ),
    );
  }
}
