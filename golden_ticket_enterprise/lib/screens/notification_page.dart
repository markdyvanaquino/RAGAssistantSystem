import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/notification.dart' as notifClass;
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/models/signalr/signalr_service.dart';
import 'package:golden_ticket_enterprise/screens/connectionstate.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:golden_ticket_enterprise/widgets/selectable_notification_tile_widget.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatefulWidget {
  final HiveSession session;
  const NotificationsPage({super.key, required this.session});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<int> _selectedNotificationIds = [];
  bool _selectionMode = false;
  String _filter = 'All';
  String _searchQuery = '';

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedNotificationIds.contains(id)) {
        _selectedNotificationIds.remove(id);
      } else {
        _selectedNotificationIds.add(id);
      }
      if (_selectedNotificationIds.isEmpty) _selectionMode = false;
    });
  }

  void _startSelection(int id) {
    setState(() {
      _selectionMode = true;
      _selectedNotificationIds.add(id);
    });
  }



  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(builder: (context, dataManager, child) {
      List<notifClass.Notification> getFilteredNotifications() {
        return dataManager.notifications.where((notif) {
          final matchesFilter = _filter == 'All' ||
              (_filter == 'Read' && notif.isRead) ||
              (_filter == 'Unread' && !notif.isRead);
          final query = _searchQuery.toLowerCase();
          final matchesSearch = notif.title.toLowerCase().contains(query) ||
              (notif.message?.toLowerCase().contains(query) ?? false) ||
              notif.notificationType.toLowerCase().contains(query);
          return matchesFilter && matchesSearch;
        }).toList();
      }

      if (!dataManager.signalRService.isConnected) {
        return DisconnectedOverlay();
      }
      void _handleTap(notifClass.Notification notif) {
        if (_selectionMode) {
          _toggleSelection(notif.notificationID);
        } else {
          handleNotificationRedirect(context, dataManager, widget.session, notif);
        }
      }

      void _deleteSelected() {
        dataManager.signalRService.markAsDelete(_selectedNotificationIds, widget.session.user.userID);
        setState(() {
          _selectedNotificationIds.clear();
          _selectionMode = false;
        });
      }

      void _readSelected(){
        dataManager.signalRService.markAsRead(_selectedNotificationIds, widget.session.user.userID);
        setState(() {
          _selectedNotificationIds.clear();
          _selectionMode = false;
        });
      }

      return Scaffold(
        backgroundColor: kSurface,
        appBar: AppBar(
          backgroundColor: kPrimary,
          title: const Text("Notifications"),
          actions: [
            if (_selectionMode)
              IconButton(
                icon: const Icon(Icons.mark_as_unread),
                onPressed:
                _selectedNotificationIds.isEmpty ? null : _readSelected,
              ),
            if (_selectionMode)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed:
                _selectedNotificationIds.isEmpty ? null : _deleteSelected,
              ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Search first (takes more space)
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search notifications...",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Compact Filter
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _filter,
                          style: TextStyle(fontSize: 14, color: Colors.black),
                          items: ['All', 'Unread', 'Read'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _filter = val!;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_selectionMode)
              Row(
                children: [
                  Checkbox(
                    value: _selectedNotificationIds.length ==
                        getFilteredNotifications().length &&
                        getFilteredNotifications().isNotEmpty,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedNotificationIds.clear();
                          _selectedNotificationIds.addAll(
                            getFilteredNotifications().map((n) => n.notificationID),
                          );
                        } else {
                          _selectedNotificationIds.clear();
                        }
                      });
                    },
                  ),
                  Text("Select All"),
                  if (_selectionMode)
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectionMode = false;
                          _selectedNotificationIds.clear();
                        });
                      },
                    ),

                ],
              ),
            Expanded(
              child: getFilteredNotifications().isEmpty
                  ? const Center(child: Text("No notifications found"))
                  : ListView.builder(
                itemCount: getFilteredNotifications().length,
                itemBuilder: (context, index) {
                  final notif = getFilteredNotifications()[index];
                  return SelectableNotificationTile(
                    notification: notif,
                    isSelected: _selectedNotificationIds
                        .contains(notif.notificationID),
                    selectionMode: _selectionMode,
                    onTap: () => _handleTap(notif),
                    onLongPress: () => _startSelection(notif.notificationID),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}
