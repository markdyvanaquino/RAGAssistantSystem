import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/user.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:provider/provider.dart';

class FeedbackReportTab extends StatefulWidget {
  final HiveSession session;

  const FeedbackReportTab({super.key, required this.session});

  @override
  State<FeedbackReportTab> createState() => _FeedbackReportTabState();
}

class _FeedbackReportTabState extends State<FeedbackReportTab> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        final allStaff = dataManager.getStaff();
        final isMobile = MediaQuery.of(context).size.width < 600;

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: allStaff.isEmpty
                ? const Center(child: Text("No staff found."))
                : isMobile
                    ? ListView.builder(
                        itemCount: allStaff.length,
                        itemBuilder: (context, index) {
                          final staff = allStaff[index];
                          final inProgressCount = dataManager.chatrooms
                              .where((chat) =>
                                  chat.ticket?.assigned?.userID ==
                                      staff.userID &&
                                  chat.ticket?.status == "In Progress")
                              .length;

                          final closedCount = dataManager.chatrooms
                              .where((chat) =>
                                  chat.ticket?.assigned?.userID ==
                                      staff.userID &&
                                  chat.ticket?.status == "Closed")
                              .length;

                          final ratings = dataManager.ratings
                              .where(
                                (r) =>
                                    r.chatroom.ticket?.assigned?.userID ==
                                    staff.userID,
                              )
                              .toList();

                          final averageRating = ratings.isNotEmpty
                              ? ratings
                                      .map((r) => r.score)
                                      .reduce((a, b) => a + b) /
                                  ratings.length
                              : null;

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                child: Text(staff.firstName[0]),
                              ),
                              title:
                                  Text('${staff.firstName} ${staff.lastName}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "Average Rating: ${averageRating?.toStringAsFixed(2) ?? 'N/A'}"),
                                  const SizedBox(height: 4),
                                  Text(
                                      "🛠 In Progress: $inProgressCount   ✅ Resolved: $closedCount"),
                                ],
                              ),
                              trailing: ElevatedButton.icon(
                                onPressed: () {
                                  showRelatedTicketsDialog(
                                      context, dataManager, staff);
                                },
                                icon: const Icon(Icons.list_alt),
                                label: const Text("View Tickets"),
                              ),
                            ),
                          );
                        },
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width),
                          child: DataTable(
                            columnSpacing: 40,
                            headingRowColor: MaterialStateColor.resolveWith(
                                (states) => Colors.grey.shade200),
                            columns: [
                              DataColumn(
                                label: Flexible(
                                  child: Text("Name", overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              DataColumn(
                                label: Flexible(
                                  child: Text("Average Rating", overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              DataColumn(
                                label: Flexible(
                                  child: Text("In Progress", overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              DataColumn(
                                label: Flexible(
                                  child: Text("Resolved", overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                              DataColumn(
                                label: Flexible(
                                  child: Text("Actions", overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                            rows: allStaff.map((staff) {
                              final ratings = dataManager.ratings
                                  .where(
                                    (r) =>
                                        r.chatroom.ticket?.assigned?.userID ==
                                        staff.userID,
                                  )
                                  .toList();
                              final inProgressCount = dataManager.chatrooms
                                  .where((chat) =>
                                      chat.ticket?.assigned?.userID ==
                                          staff.userID &&
                                      chat.ticket?.status == "In Progress")
                                  .length;

                              final closedCount = dataManager.chatrooms
                                  .where((chat) =>
                                      chat.ticket?.assigned?.userID ==
                                          staff.userID &&
                                      chat.ticket?.status == "Closed")
                                  .length;

                              final averageRating = ratings.isNotEmpty
                                  ? ratings
                                          .map((r) => r.score)
                                          .reduce((a, b) => a + b) /
                                      ratings.length
                                  : null;

                              return DataRow(
                                cells: [
                                  DataCell(Text(
                                      '${staff.firstName} ${staff.lastName}')),
                                  DataCell(Text(
                                      averageRating?.toStringAsFixed(2) ??
                                          'N/A',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500))),
                                  DataCell(Text(inProgressCount.toString())),
                                  DataCell(Text(closedCount.toString())),
                                  DataCell(
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        showRelatedTicketsDialog(
                                            context, dataManager, staff);
                                      },
                                      icon: const Icon(Icons.visibility),
                                      label: const Text("View Tickets"),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        );
      },
    );
  }
}

void showRelatedTicketsDialog(
    BuildContext context, DataManager dataManager, User user) {
  final chatrooms = dataManager.chatrooms
      .where((chat) => chat.ticket?.assigned?.userID == user.userID)
      .toList();

  final inProgress =
      chatrooms.where((chat) => chat.ticket?.status == "In Progress").toList();
  final closed =
      chatrooms.where((chat) => chat.ticket?.status == "Closed").toList();

  final ratings = dataManager.ratings;

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = MediaQuery.of(context).size.width * 0.8;
            final maxHeight = MediaQuery.of(context).size.height * 0.9;

            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tickets by ${user.firstName} ${user.lastName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (inProgress.isNotEmpty) ...[
                            const Text("🛠 Currently Handling",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...inProgress.map((chat) => _buildTicketCard(chat, ratings)),
                            const SizedBox(height: 16),
                          ],
                          if (closed.isNotEmpty) ...[
                            const Text("✅ Resolved Tickets",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...closed.map((chat) => _buildTicketCard(chat, ratings)),
                          ],
                          if (inProgress.isEmpty && closed.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 12.0),
                              child: Text("No tickets found."),
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
      );
    },
  );
}

Widget _buildTicketCard(chat, List ratings) {
  final rating = ratings
      .where((r) => r.chatroom.chatroomID == chat.chatroomID)
      .firstOrNull;

  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: ListTile(
      title: Text(chat.ticket?.ticketTitle ?? "No Title",
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: rating != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(rating.score.toStringAsFixed(1)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '"${rating.feedback}"',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            )
          : const Text("No rating"),
    ),
  );
}
