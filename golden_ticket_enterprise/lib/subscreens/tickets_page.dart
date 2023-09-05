import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_ticket_enterprise/entities/ticket.dart';
import 'package:golden_ticket_enterprise/models/signalr/signalr_service.dart';
import 'package:golden_ticket_enterprise/widgets/edit_ticket_widget.dart';
import 'package:golden_ticket_enterprise/widgets/notification_widget.dart';
import 'package:golden_ticket_enterprise/widgets/ticket_detail_widget.dart';
import 'package:golden_ticket_enterprise/widgets/ticket_tile_widget.dart';
import 'package:provider/provider.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';

class TicketsPage extends StatefulWidget {
  final HiveSession? session;

  TicketsPage({super.key, required this.session});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  List<Ticket> _filteredTickets = [];
  bool _assignedToMeOnly = false;
  bool _includeClosed = false;
  bool _includeUnresolved = false;
  String? selectedStatus = 'All';
  String? selectedMainTag = 'All';
  String? selectedPriority = 'All';
  String? selectedSubTag;

  int _currentPage = 1;
  int _ticketsPerPage = 10;

  @override
  void initState() {
    super.initState();
    if (widget.session == null) {
      context.go("/login");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dataManager = Provider.of<DataManager>(context, listen: true);

    // Ensure tickets are loaded before applying filters
    if (dataManager.tickets.isNotEmpty) {
      _applyFilters(dataManager);
    }
  }

  void _applyFilters(DataManager dataManager) {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredTickets = dataManager.tickets.where((ticket) {
        bool matchesSearch = ticket.ticketTitle.toLowerCase().contains(query) ||
            ticket.ticketID.toString().contains(query) ||
            ticket.author.firstName.toLowerCase().contains(query) == true ||
            ticket.author.lastName.toLowerCase().contains(query) == true;

        bool matchesStatus = selectedStatus == 'All' || ticket.status == selectedStatus;
        bool matchesMainTag = selectedMainTag == 'All' || (ticket.mainTag?.tagName == selectedMainTag);
        bool matchesSubTag = selectedSubTag == 'All' || selectedSubTag == null || (ticket.subTag?.subTagName == selectedSubTag);
        bool matchesPriority = selectedPriority == 'All' || ticket.priority == selectedPriority;
        bool matchesAssignedToMe = !_assignedToMeOnly || (ticket.assigned?.userID == widget.session?.user.userID);

        bool isClosed = ticket.status.toLowerCase() == 'closed';
        bool isUnresolvedStatus = ticket.status.toLowerCase() == 'unresolved';

        bool matchesClosed = _includeClosed || !isClosed;
        bool matchesUnresolved = _includeUnresolved || !isUnresolvedStatus;

        return matchesSearch &&
            matchesStatus &&
            matchesMainTag &&
            matchesSubTag &&
            matchesPriority &&
            matchesAssignedToMe &&
            matchesClosed &&
            matchesUnresolved;
      }).toList();

      // Sort tickets by priority (High > Medium > Low)
      _filteredTickets.sort((a, b) {
        List<String> priorityOrder = ['High', 'Medium', 'Low'];
        int priorityCompare = priorityOrder.indexOf(a.priority).compareTo(priorityOrder.indexOf(b.priority));
        if (priorityCompare != 0) return priorityCompare;

        return b.createdAt.compareTo(a.createdAt);
      });
    });

    // Reset pagination when filters change
    _currentPage = 1;
  }


  List<Ticket> get _paginatedTickets {
    int start = (_currentPage - 1) * _ticketsPerPage;
    int end = (_currentPage * _ticketsPerPage).clamp(0, _filteredTickets.length);
    return _filteredTickets.sublist(start, end);
  }

  int get _totalPages => (_filteredTickets.length / _ticketsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        Map<String, List<String>> tags = {
          'All': [],
          for (var tag in dataManager.mainTags)
            tag.tagName: tag.subTags.map((e) => e.subTagName).toList(),
        };

        List<String> statuses = ['All', ...dataManager.status];
        List<String> priorities = ['All', ...dataManager.priorities];

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 600;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dataManager.mainTags.isEmpty)
                    Center(child: CircularProgressIndicator())
                  else
                    ExpansionTile(
                      initiallyExpanded:
                      !isMobile, // ✅ Expanded by default on mobile, collapsed on desktop
                      title: Text("Filters",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      children: [
                        _buildFilters(tags, statuses, priorities, isRow: !isMobile)
                      ],
                    ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _applyFilters(dataManager),
                    decoration: InputDecoration(
                      hintText: "Search tickets...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: _filteredTickets.isEmpty
                        ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? "No tickets available"
                            : "No tickets found",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                    )
                        : Scrollbar(
                      controller: scrollController,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: _paginatedTickets.length,
                        itemBuilder: (context, index) {
                          final ticket = _paginatedTickets[index];
                          return TicketTile(
                            ticket: ticket,
                            session: widget.session,
                            onViewPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => TicketDetailsPopup(
                                    ticket: ticket,
                                    onChatPressed: () => handleChat(dataManager, ticket),
                                ),
                              );
                            },
                            onChatPressed: () {
                              try {
                                openChatroom(context, widget.session!, dataManager, dataManager.findChatroomByTicketID(ticket.ticketID)!.chatroomID);
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
                            },
                            onEditPressed: () {
                              if(ticket.assigned != null){
                                if(ticket.assigned!.userID != widget.session!.user.userID && widget.session!.user.role != "Admin"){
                                  TopNotification.show(
                                      context: context,
                                      message: "This ticket is not assigned to you",
                                      backgroundColor: Colors.redAccent,
                                      duration: Duration(seconds: 2),
                                      textColor: Colors.white,
                                      onTap: () {
                                        TopNotification.dismiss();
                                      }
                                  );
                                  return;
                                }
                              }
                              showDialog(
                                context: context,
                                builder: (context) => TicketModifyPopup(ticket: ticket),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  if (_filteredTickets.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_totalPages, (index) {
                          final pageNum = index + 1;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _currentPage == pageNum
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[300],
                                foregroundColor: _currentPage == pageNum
                                    ? Colors.white
                                    : Colors.black,
                                minimumSize: Size(36, 36),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () {
                                setState(() {
                                  _currentPage = pageNum;
                                });
                              },
                              child: Text('$pageNum'),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFilters(Map<String, List<String>> tags, List<String> statuses, List<String> priorities, {bool isRow = false}) {
    bool isSubTagDisabled = selectedMainTag == 'All';

    List<Widget> dropdownFilters = [
      _buildDropdown("Status", selectedStatus, statuses, (value) {
        setState(() {
          selectedStatus = value;
        });
        _applyFilters(Provider.of<DataManager>(context, listen: false));
      }),
      _buildDropdown("Priority", selectedPriority, priorities, (value) {
        setState(() {
          selectedPriority = value;
        });
        _applyFilters(Provider.of<DataManager>(context, listen: false));
      }),
      _buildDropdown("Main Tag", selectedMainTag, tags.keys.toList(), (value) {
        setState(() {
          selectedMainTag = value;
          selectedSubTag = null;
        });
        _applyFilters(Provider.of<DataManager>(context, listen: false));
      }),
      _buildDropdown(
        "Sub Tag",
        isSubTagDisabled ? null : selectedSubTag,
        isSubTagDisabled ? [] : ['All', ...?tags[selectedMainTag]],
        isSubTagDisabled ? null : (value) {
          setState(() {
            selectedSubTag = value;
          });
          _applyFilters(Provider.of<DataManager>(context, listen: false));
        },
        isDisabled: isSubTagDisabled,
      ),
    ];

    Widget checkboxRow = Wrap(
      spacing: 20,
      runSpacing: 10,
      children: [
        if(widget.session!.user.role != 'Employee')_buildCheckbox("Assigned to Me", _assignedToMeOnly, (val) {
          setState(() => _assignedToMeOnly = val);
          _applyFilters(Provider.of<DataManager>(context, listen: false));
        }),
        _buildCheckbox("Include Closed", _includeClosed, (val) {
          setState(() => _includeClosed = val);
          _applyFilters(Provider.of<DataManager>(context, listen: false));
        }),
        _buildCheckbox("Include Unresolved", _includeUnresolved, (val) {
          setState(() => _includeUnresolved = val);
          _applyFilters(Provider.of<DataManager>(context, listen: false));
        }),
      ],
    );

    return isRow
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: dropdownFilters
              .expand((widget) => [Expanded(child: widget), SizedBox(width: 10)])
              .toList()
            ..removeLast(),
        ),
        SizedBox(height: 10),
        checkboxRow,
      ],
    )
        : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...dropdownFilters
            .expand((widget) => [widget, SizedBox(height: 10)]).toList()
          ..removeLast(),
        SizedBox(height: 10),
        checkboxRow,
      ],
    );
  }
  void handleChat(DataManager dataManager, Ticket ticket){
    try {
      openChatroom(context, widget.session!, dataManager, dataManager.findChatroomByTicketID(ticket.ticketID)!.chatroomID);
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
  Widget _buildCheckbox(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
        Text(label),
      ],
    );
  }

  Widget _buildDropdown(String label, String? value, List<String>? items, ValueChanged<String?>? onChanged, {bool isDisabled = false}) {
    return DropdownButtonFormField<String>(
      value: value,
      padding: EdgeInsets.only(top: 5),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      items: isDisabled
          ? [] // Empty dropdown when disabled
          : (items ?? []).map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: isDisabled ? null : onChanged, // Disable dropdown if needed
      disabledHint: Text(label, style: TextStyle(color: Colors.grey)), // Greyed-out label
    );
  }
}
