import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/rating.dart';
import 'package:golden_ticket_enterprise/entities/chatroom.dart';
import 'package:golden_ticket_enterprise/models/time_utils.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';

class ChatroomTile extends StatelessWidget {
  final Chatroom chatroom;
  final Rating? rating;
  final VoidCallback onOpenChatPressed;

  const ChatroomTile({
    super.key,
    required this.chatroom,
    required this.rating,
    required this.onOpenChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chatroom name
            Text(
              chatroom.ticket != null ? chatroom.ticket?.ticketTitle ?? "New Chat" : "New Chat",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            // Author
            SelectableText(
              "Author: ${chatroom.author?.firstName ?? "Unknown"} ${chatroom.author?.lastName ?? ""}",
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 6),

            // Creation Date
            Text(
              TimeUtil.formatCreationDate(chatroom.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),

            const SizedBox(height: 10),

            // Rating (if exists)
            if (rating != null)
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    "${rating!.score}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

            // Open Chat Button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onOpenChatPressed,
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text("Open Chat"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
