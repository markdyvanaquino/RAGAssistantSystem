import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/rating.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/models/signalr/signalr_service.dart';
import 'package:golden_ticket_enterprise/widgets/chatroom_tile.dart';
import 'package:intl/intl.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:provider/provider.dart';

class ChatbotPerformanceTab extends StatefulWidget {
  final HiveSession session;
  const ChatbotPerformanceTab({super.key, required this.session});

  @override
  State<ChatbotPerformanceTab> createState() => _ChatbotPerformanceTabState();
}

class _ChatbotPerformanceTabState extends State<ChatbotPerformanceTab> {
  late DateTime fromDate;
  late DateTime toDate;

  int? selectedScore;
  String selectedRatingFilter = 'All'; // 'All', 'With', 'Without'

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    fromDate = DateTime(now.year, 1, 1);
    toDate = now;
  }

  Future<void> pickDate(BuildContext context, bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? fromDate : toDate,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  Widget _buildDatePicker(String label, DateTime date, bool isFrom) {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return InkWell(
      onTap: () => pickDate(context, isFrom),
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isMobile
                    ? "$label: ${DateFormat('MMM dd, yyyy').format(date)}"
                    : "$label: ${DateFormat('MMM dd, yyyy').format(date)}",
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;
        final childWidth = isMobile ? double.infinity : (constraints.maxWidth / 4) - 12;

        final children = [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: childWidth),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: _buildDatePicker("From", fromDate, true),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: childWidth),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: _buildDatePicker("To", toDate, false),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: childWidth),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: DropdownButtonFormField<int?>(
                isExpanded: true, // important for avoiding overflow
                value: selectedScore,
                decoration: const InputDecoration(
                  labelText: "Rating Score",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text("All")),
                  DropdownMenuItem(value: 1, child: Text("1")),
                  DropdownMenuItem(value: 2, child: Text("2")),
                  DropdownMenuItem(value: 3, child: Text("3")),
                  DropdownMenuItem(value: 4, child: Text("4")),
                  DropdownMenuItem(value: 5, child: Text("5")),
                ],
                onChanged: (val) => setState(() => selectedScore = val),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: childWidth),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: DropdownButtonFormField<String>(
                isExpanded: true, // important for avoiding overflow
                value: selectedRatingFilter,
                decoration: const InputDecoration(
                  labelText: "Rating Filter",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
                items: const [
                  DropdownMenuItem(value: 'All', child: Text("All")),
                  DropdownMenuItem(value: 'With', child: Text("With Rating")),
                  DropdownMenuItem(value: 'Without', child: Text("Without Rating")),
                ],
                onChanged: (val) => setState(() => selectedRatingFilter = val!),
              ),
            ),
          ),
        ];

        return isMobile
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)
            : Wrap(spacing: 0, runSpacing: 0, children: children);
      },
    );
  }

  List<dynamic> _filterChatrooms(List chatrooms) {
    return chatrooms.where((chatroom) {
      final createdAt = chatroom.createdAt;
      return createdAt != null &&
          !createdAt.isBefore(fromDate) &&
          !createdAt.isAfter(toDate);
    }).toList();
  }

  List<dynamic> _applyRatingFilters(List chatrooms, Map<int, Rating> ratingMap) {
    return chatrooms.where((c) {
      final rating = ratingMap[c.chatroomID];

      if (selectedRatingFilter == 'With' && rating == null) return false;
      if (selectedRatingFilter == 'Without' && rating != null) return false;
      if (selectedScore != null && (rating == null || rating.score != selectedScore)) return false;

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(builder: (context, dataManager, child) {
      final filtered = _filterChatrooms(dataManager.chatrooms);
      final aiResolved = filtered
          .where((c) => c.ticket == null && c.isClosed == true)
          .toList();

      final ratingsMap = {
        for (var r in dataManager.ratings) r.chatroom.chatroomID: r
      };

      final aiResolvedFiltered = _applyRatingFilters(aiResolved, ratingsMap);
      final sentToLive = filtered.where((c) => c.ticket != null).toList();

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopFilters(),
              const SizedBox(height: 16),
              if(filtered.isEmpty) Text('No data to filter.'),
              const SizedBox(height: 16),
              if(filtered.isNotEmpty) _buildSection("AI Resolved", aiResolvedFiltered, dataManager),
              const SizedBox(height: 16),
              if(filtered.isNotEmpty) _buildSection("Sent to live agent", sentToLive, dataManager),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSection(String title, List items, DataManager dataManager) {
    return ExpansionTile(
      title: Text(
        "$title (${items.length})",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: items.map((c) {
        final rating = dataManager.ratings.where(
              (r) => r.chatroom.chatroomID == c.chatroomID
        ).firstOrNull;

        return ChatroomTile(
          chatroom: c,
          rating: rating,
          onOpenChatPressed: () {
            openChatroom(context, widget.session, dataManager, c.chatroomID);
          },
        );
      }).toList(),
    );
  }
}
