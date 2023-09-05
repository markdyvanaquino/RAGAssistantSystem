import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/entities/ticket.dart';
import 'package:golden_ticket_enterprise/models/signalr/signalr_service.dart';
import 'package:golden_ticket_enterprise/models/time_utils.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:golden_ticket_enterprise/widgets/notification_widget.dart';
import 'package:golden_ticket_enterprise/widgets/ticket_detail_widget.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  final HiveSession? session;

  const DashboardPage({super.key, required this.session});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double maxWidth = 1200; // Prevents stretching on ultra-wide screens

    int columns = 4; // Default for large screens
    if (screenWidth < 1100) columns = 3;
    if (screenWidth < 900) columns = 2;
    if (screenWidth < 600) columns = 1;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Consumer<DataManager>(
                builder: (context, dataManager, _) {
                  // ✅ Get Tickets from DataManager
                  List<Ticket> tickets = dataManager.getRecentTickets();

                  // ✅ Count tickets per category
                  Map<String, int> ticketCounts = {
                    "Open": tickets.where((t) => t.status == "Open").length,
                    "In Progress": tickets.where((t) => t.status == "In Progress").length,
                    "Postponed": tickets.where((t) => t.status == "Postponed").length,
                    "Unresolved": tickets.where((t) => t.status == "Unresolved").length,
                  };

                  // ✅ Recent Tickets (Last 10)
                  List<Ticket> recentTickets = tickets.take(10).toList();

                  return Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: CustomScrollView( // Changed to CustomScrollView
                      controller: _scrollController,
                      slivers: [
                        // **Ticket Overview**
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Ticket Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),

                              // **Stats Grid (Responsive)**
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemCount: ticketCounts.length,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio: 2.5,
                                    ),
                                    itemBuilder: (context, index) {
                                      String status = ticketCounts.keys.elementAt(index);
                                      int count = ticketCounts[status] ?? 0;
                                      Color color = getStatusColor(status) ?? Colors.grey;

                                      return Card(
                                        elevation: 2,
                                        color: color.withOpacity(0.2),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(vertical: 16),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: color,
                                                child: Text("$count",
                                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                              ),
                                              SizedBox(height: 5),
                                              Flexible(
                                                  child: Text(status, style: TextStyle(fontSize: 14))
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        SliverToBoxAdapter(child: SizedBox(height: 20)),

                        // **Recent Tickets**
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Recent Tickets", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),

                              recentTickets.isEmpty
                                  ? Center(child: Text("No recent tickets"))
                                  : ListView.builder(
                                shrinkWrap: true, // Allow it to take only the space needed
                                physics: NeverScrollableScrollPhysics(), // Avoid conflicts with parent scroll
                                itemCount: recentTickets.length,
                                itemBuilder: (context, index) {
                                  Ticket ticket = recentTickets[index];
                                  return Card(
                                    child: ListTile(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => TicketDetailsPopup(
                                            ticket: ticket,
                                            onChatPressed: () => handleChat(dataManager, ticket),
                                          ),
                                        );
                                      },
                                      leading: Icon(Icons.confirmation_number, color: Colors.blue),
                                      title: Text("#${ticket.ticketID}: ${ticket.ticketTitle ?? "No title provided"}"),
                                      subtitle: Row(
                                        children: [
                                          Chip(
                                            label: Text(ticket.priority!,
                                                style: TextStyle(color: Colors.white, fontSize: 12)),
                                            backgroundColor: getPriorityColor(ticket.priority!),
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          ),
                                          Chip(
                                            label: Text(ticket.status,
                                                style: TextStyle(color: Colors.white, fontSize: 12)),
                                            backgroundColor: getStatusColor(ticket.status),
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            TimeUtil.formatTimestamp(ticket.createdAt), // Show only date
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void handleChat(DataManager dataManager, Ticket ticket){
    try {
      openChatroom(context, widget.session!, dataManager, dataManager.findChatroomByTicketID(
          ticket.ticketID)!.chatroomID);
    }catch(err){
      TopNotification.show(
          context: context,
          message: "Error chatroom could not be found!",
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
          textColor: Colors.white,
          onTap: () {
            TopNotification.dismiss();
          }
      );
    }
  }
}
