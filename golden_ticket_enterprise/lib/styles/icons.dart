import 'package:flutter/material.dart';

IconData getActionHandlerIcon(String status) {
  IconData icon;
  Color color;

  switch (status.toLowerCase()) {
    case 'created':
      icon = Icons.add_circle_outline;
      color = Colors.green;
      break;
    case 'assigned':
      icon = Icons.assignment_turned_in;
      color = Colors.blue;
      break;
    case 're-assigned':
      icon = Icons.assignment_returned;
      color = Colors.orange;
      break;
    case 'in progress':
      icon = Icons.timelapse;
      color = Colors.yellow;
      break;
    case 'postponed':
      icon = Icons.pause_circle_filled;
      color = Colors.grey;
      break;
    case 'closed':
      icon = Icons.check_circle_outline;
      color = Colors.green;
      break;
    case 'unresolved':
      icon = Icons.error_outline;
      color = Colors.red;
      break;
    case 're-opened':
      icon = Icons.refresh_outlined;
      color = Colors.blueAccent;
      break;
    case 'priority':
      icon = Icons.priority_high_rounded;
      color = Colors.blueAccent;
      break;
    case 'title':
      icon = Icons.title_outlined;
      color = Colors.blueAccent;
      break;
    case 'maintag':
      icon = Icons.tag_outlined;
      color = Colors.blueAccent;
      break;
    case 'subtag':
      icon = Icons.tag_outlined;
      color = Colors.blueAccent;
      break;
    default:
      icon = Icons.help_outline;
      color = Colors.black;
  }

  return icon;
}
