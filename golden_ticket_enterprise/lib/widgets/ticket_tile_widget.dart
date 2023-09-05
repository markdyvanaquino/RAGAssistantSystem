import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/ticket.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/models/time_utils.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';

class TicketTile extends StatelessWidget {
  final HiveSession? session;
  final Ticket ticket;
  final VoidCallback onChatPressed;
  final VoidCallback onViewPressed;
  final VoidCallback onEditPressed;

  const TicketTile({
    Key? key,
    required this.session,
    required this.ticket,
    required this.onChatPressed,
    required this.onViewPressed,
    required this.onEditPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onViewPressed,
        hoverColor: kPrimaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ticket.ticketTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(ticket.mainTag?.tagName ?? "No main tag", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent),
                  Chip(label: Text(ticket.subTag?.subTagName ?? "No sub tag", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.blueAccent),
                  Chip(
                    label: Text(ticket.status, style: const TextStyle(color: Colors.white)),
                    backgroundColor: getStatusColor(ticket.status),
                  ),
                  Chip(
                    label: Text(ticket.priority, style: const TextStyle(color: Colors.white)),
                    backgroundColor: getPriorityColor(ticket.priority),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SelectableText("ID: ${ticket.ticketID}", style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              const SizedBox(height: 6),
              SelectableText("Author: ${ticket.author.firstName} ${ticket.author.lastName}", style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              const SizedBox(height: 6),
              SelectableText("Assignee: ${ticket.assigned != null ? '${ticket.assigned!.firstName} ${ticket.assigned!.lastName}' : "None assigned"}", style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    TimeUtil.formatCreationDate(ticket.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue), onPressed: onChatPressed),
                      if (
                       session!.user.role != "Employee" && (
                          (ticket.assigned != null && ticket.assigned?.userID == session!.user.userID) ||
                              ticket.assigned == null ||
                              session!.user.role == "Admin"
                       )
                      )
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: onEditPressed,
                        )

                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
