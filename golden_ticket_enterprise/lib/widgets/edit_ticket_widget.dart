import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/entities/ticket.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart' as Session;

class TicketModifyPopup extends StatefulWidget {
  final Ticket ticket;


  const TicketModifyPopup({super.key, required this.ticket});

  @override
  State<TicketModifyPopup> createState() => _TicketModifyPopupState();
}

class _TicketModifyPopupState extends State<TicketModifyPopup> {
  late TextEditingController _titleController;
  String? selectedStatus;
  String? selectedMainTag;
  String? selectedSubTag;
  String? selectedPriority;
  int? selectedAgentID; // Store Agent ID
  String? errorMessage; // To show validation errors

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.ticket.ticketTitle);
    selectedStatus = widget.ticket.status;
    selectedMainTag = widget.ticket.mainTag?.tagName;
    selectedSubTag = widget.ticket.subTag?.subTagName;
    selectedPriority = widget.ticket.priority;
    selectedAgentID = widget.ticket.assigned?.userID; // Assign Agent ID
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _saveTicket(DataManager dataManager) {
    setState(() => errorMessage = null);

    // Validate Title
    if (_titleController.text.trim().isEmpty) {
      setState(() => errorMessage = "Title cannot be empty.");
      return;
    }

    // Prevent unassigning if status is "In Progress"
    if (selectedStatus == "In Progress" && (selectedAgentID == null || selectedAgentID == 0)) {
      setState(() => errorMessage = "Cannot unassign while status is 'In Progress'. Set status to 'Open' first.");
      return;
    }
    if (selectedStatus == "Closed" && (selectedAgentID == null || selectedAgentID == 0)) {
      setState(() => errorMessage = "Cannot change the status of the ticket to 'Closed'. Assignee is required!");
      return;
    }
    if (selectedStatus == "Unresolved" && (selectedAgentID == null || selectedAgentID == 0)) {
      setState(() => errorMessage = "Cannot change the status of the ticket to 'Unresolved'. Assignee is required!");
      return;
    }

    dataManager.signalRService.updateTicket(
      widget.ticket.ticketID,
      _titleController.text.trim(),
      selectedStatus!,
      selectedPriority!,
      selectedMainTag == "None" ? null : selectedMainTag,
      selectedSubTag == "None" ? null : selectedSubTag,
      selectedAgentID == 0 ? null : selectedAgentID,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        Map<String, List<String>> tags = {
          'None': [],
          for (var tag in dataManager.mainTags)
            tag.tagName: tag.subTags.map((e) => e.subTagName).toList(),
        };

        List<String> statuses = dataManager.status;
        List<String> priorities = dataManager.priorities;

        var currentUser = Hive.box<Session.HiveSession>('sessionBox').get('user')!.user;
        bool isAdmin = currentUser.role == 'Admin';

        // Restrict agent assignment for non-admins
        Map<int, String> agentMap = {0: "None Assigned"};
        if (isAdmin) {
          for (var agent in dataManager.getStaff()) {
            agentMap[agent.userID] = '${agent.firstName} ${agent.lastName}';
          }
        } else {
          agentMap[currentUser.userID] = '${currentUser.firstName} ${currentUser.lastName}';
        }

        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Container(
              width: MediaQuery.of(context).size.width > 600 ? 500 : double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        Text('Edit Ticket', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),

                        if (errorMessage != null) ...[
                          Text(errorMessage!, style: TextStyle(color: Colors.red)),
                          SizedBox(height: 10),
                        ],

                        _buildTextField("Title", _titleController),
                        SizedBox(height: 10),
                        _buildDropdown("Status", selectedStatus, statuses, (value) {
                          setState(() => selectedStatus = value);
                        }),
                        SizedBox(height: 10),
                        _buildDropdown("Main Tag", selectedMainTag, tags.keys.toList(), (value) {
                          setState(() {
                            selectedMainTag = value;
                            selectedSubTag = null;
                          });
                        }),
                        SizedBox(height: 10),
                        _buildDropdown(
                          "Sub Tag",
                          selectedSubTag,
                          selectedMainTag != null && selectedMainTag != 'None'
                              ? ['None', ...tags[selectedMainTag]!]
                              : ['None'],
                              (value) {
                            setState(() => selectedSubTag = value);
                          },
                          disabled: selectedMainTag == null || selectedMainTag == 'None',
                        ),
                        SizedBox(height: 10),
                        _buildDropdown("Priority", selectedPriority, priorities, (value) {
                          setState(() => selectedPriority = value);
                        }),
                        SizedBox(height: 10),

                        // Agent Assignment Dropdown
                        DropdownButtonFormField<int>(
                          value: selectedAgentID ?? 0,
                          decoration: InputDecoration(
                            labelText: "Assign to",
                            border: OutlineInputBorder(),
                          ),
                          items: agentMap.entries.map((entry) {
                            return DropdownMenuItem<int>(
                              value: entry.key,
                              child: Text(entry.value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (selectedStatus == "In Progress" && value == 0) {
                              setState(() => errorMessage = "Cannot unassign while status is 'In Progress'. Set status to 'Open' first.");
                              return;
                            }
                            if (selectedStatus == "Closed" && value == 0) {
                              setState(() => errorMessage = "Cannot change the status of the ticket to 'Closed'. Assignee is required!");
                              return;
                            }
                            if (selectedStatus == "Unresolved" && value == 0) {
                              setState(() => errorMessage = "Cannot change the status of the ticket to 'Unresolved'. Assignee is required!");
                              return;
                            }
                            setState(() {
                              selectedAgentID = value;
                              if (value != 0) selectedStatus = "In Progress"; // Auto-update status
                            });
                          },
                        ),
                        SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              onPressed: () => _saveTicket(dataManager),
                              child: Text('Save', style: TextStyle(color: Colors.white),),
                            ),
                          ],
                        ),
                      ],
                    )
                  ),

                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      maxLength: 75,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> items, ValueChanged<String?> onChanged, {bool disabled = false}) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        enabled: !disabled,
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: disabled ? null : onChanged,
    );
  }
}
