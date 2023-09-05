import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:golden_ticket_enterprise/entities/ticket.dart';
import 'package:golden_ticket_enterprise/models/time_utils.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:golden_ticket_enterprise/styles/icons.dart';

class TicketDetailsPopup extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onChatPressed;

  const TicketDetailsPopup({Key? key, required this.ticket, required this.onChatPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Title bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ticket',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(Icons.chat, color: Colors.white),
                              tooltip: 'Open Chat',
                              onPressed: () {
                                onChatPressed();
                                Navigator.pop(context);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.white),
                              tooltip: 'Close',
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      )

                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${ticket.ticketID}: ${ticket.ticketTitle ?? "No title provided"}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: kPrimary,
                          ),
                        ),
                        SizedBox(height: 12),
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _infoRow(Icons.person, 'Author:', '${ticket.author.firstName} ${ticket.author.lastName}'),
                                SizedBox(height: 6),
                                _infoRow(Icons.assignment_ind, 'Assigned:',
                                    ticket.assigned != null
                                        ? '${ticket.assigned!.firstName} ${ticket.assigned!.lastName}'
                                        : 'None assigned'),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    _chipRow('Priority:', ticket.priority, getPriorityColor(ticket.priority)),
                                    _chipRow('Status:', ticket.status, getStatusColor(ticket.status)),
                                    if (ticket.mainTag != null)
                                      _chipRow('Main Tag:', ticket.mainTag!.tagName, Colors.redAccent),
                                    _chipRow('Sub Tag:', ticket.subTag?.subTagName ?? 'No Sub Tag Provided', Colors.blueAccent),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Created At:',
                                            style: TextStyle(fontWeight: FontWeight.bold)),
                                        SizedBox(width: 6),
                                        Text(TimeUtil.formatCreationDate(ticket.createdAt)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text('Ticket History',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.all(12),
                          height: 300,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 15,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 2,
                                  color: kPrimary.withOpacity(0.5),
                                ),
                              ),
                              ListView.builder(
                                itemCount: ticket.ticketHistory?.length ?? 0,
                                itemBuilder: (context, index) {
                                  var sortedHistory = [...?ticket.ticketHistory]
                                    ..sort((a, b) => a.actionDate.compareTo(b.actionDate));
                                  var historyItem = sortedHistory[index];

                                  return Container(
                                    margin: EdgeInsets.only(bottom: 20),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 30,
                                          alignment: Alignment.center,
                                          child: CircleAvatar(
                                            radius: 12,
                                            backgroundColor: kPrimary,
                                            child: Icon(
                                              getActionHandlerIcon(historyItem.action),
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: kPrimaryContainer,
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.05),
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
                                                )
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${TimeUtil.formatCreationDate(historyItem.actionDate)}: ${historyItem.action}',
                                                  style: TextStyle(
                                                      fontWeight: FontWeight.bold, fontSize: 14),
                                                ),
                                                SizedBox(height: 4),
                                                MarkdownBody(
                                                  data: historyItem.actionMessage,
                                                  styleSheet: MarkdownStyleSheet(
                                                    p: TextStyle(fontSize: 14, color: Colors.black),
                                                    strong:
                                                    const TextStyle(fontWeight: FontWeight.bold),
                                                    blockquote: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontStyle: FontStyle.italic),
                                                  ),
                                                  selectable: true,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        SizedBox(width: 8),
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(width: 4),
        Text(value),
      ],
    );
  }

  Widget _chipRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(width: 6),
          Chip(
            label: Text(value, style: TextStyle(fontWeight: FontWeight.normal)),
            backgroundColor: color,
            labelStyle: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
