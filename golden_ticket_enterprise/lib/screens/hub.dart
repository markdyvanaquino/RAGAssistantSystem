import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_ticket_enterprise/entities/chatroom.dart';
import 'package:golden_ticket_enterprise/entities/main_tag.dart';
import 'package:golden_ticket_enterprise/entities/notification.dart'
    as notifClass;
import 'package:golden_ticket_enterprise/entities/user.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/models/notification_overlay.dart';
import 'package:golden_ticket_enterprise/models/signalr/signalr_service.dart';
import 'package:golden_ticket_enterprise/screens/connectionstate.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:golden_ticket_enterprise/screens/notification_page.dart';
import 'package:golden_ticket_enterprise/widgets/notification_tile_widget.dart';
import 'package:golden_ticket_enterprise/widgets/notification_widget.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

class HubPage extends StatefulWidget {
  final HiveSession? session;
  final StatefulNavigationShell child;
  final DataManager dataManager;
  List<MainTag> mainTags = [];
  HubPage(
      {Key? key,
      required this.session,
      required this.child,
      required this.dataManager})
      : super(key: key);

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> {
  late DataManager dm;
  late int _selectedIndex; // Track selected index
  bool _isInitialized = false;
  bool _eventsMounted = false;

  @override
  void initState() {
    _selectedIndex = widget.child.currentIndex;
    super.initState();
    dm = Provider.of<DataManager>(context, listen: false);
    if(!_eventsMounted) {
      _eventsMounted = true;
      dm.signalRService.addOnReceiveSupportListener(_handleReceiveSupport);
      dm.signalRService.addOnNotificationListener(_handleNotification);
      dm.signalRService.addOnUserUpdateListener(_handleUserUpdate);
    }
    dm.signalRService.onMaximumChatroom = () {
      dm.enableRequestButton();
      TopNotification.show(
        context: context,
        message: "Maximum Chatroom has been reached",
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 2),
        textColor: Colors.white,
        onTap: () => TopNotification.dismiss(),
      );
    };
  }

  @override
  void didChangeDependencies() {
    if (!_isInitialized && !widget.dataManager.signalRService.isConnected) {
      log("HubPage: Initializing SignalR Connection...");
      widget.dataManager.signalRService.initializeConnection();
      _isInitialized = true;
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    dm.signalRService.removeOnNotificationListener(_handleNotification);
    dm.signalRService.removeOnUserListener(_handleUserUpdate);
    dm.signalRService.removeOnReceiveSupportListener(_handleReceiveSupport);
    super.dispose();
  }

  void _onDrawerItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    widget.child
        .goBranch(index, initialLocation: index == widget.child.currentIndex);
  }

  void _handleReceiveSupport(Chatroom chatroom) {
    openChatroom(context, widget.session!, dm, chatroom.chatroomID);
  }

  void _handleNotification(notifClass.Notification notification) {
    if (notification.notificationType == 'Chatroom' &&
        (dm.isInChatroom && dm.chatroomID == notification.referenceID)) return;
    NotificationOverlay.show(context, message: notification.title, onTap: () {
      if (notification.referenceID != null) {
        handleNotificationRedirect(context, dm, widget.session!, notification);
      }
    });
  }

  void _handleUserUpdate(User user) async{
    if(user.userID == widget.session!.user.userID && user.isDisabled){
      var box = Hive.box<HiveSession>('sessionBox');
      context.go('/login');
      await box.delete('user'); // Clear session
      await dm.closeConnection();
      TopNotification.show(
        context: context,
        message: "Your Account has been Disabled!",
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 2)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session == null) {
      return SizedBox.shrink(); // Prevents UI from rendering if redirecting
    }

    return Consumer<DataManager>(builder: (context, dataManager, child) {
      if (!dataManager.signalRService.isConnected) {
        return DisconnectedOverlay();
      }
      int unreadCount =
          dataManager.notifications.where((notif) => !notif.isRead).length;

      void _logout() async {
        var box = Hive.box<HiveSession>('sessionBox');
        context.go('/login');
        await box.delete('user'); // Clear session
        await dataManager.closeConnection();
      }

      return Scaffold(
          backgroundColor: kSurface,
          appBar: AppBar(
            backgroundColor: kPrimary,
            title: Text(_getAppBarTitle()), // Dynamic title
            actions: [
              PopupMenuButton(
                icon: Stack(clipBehavior: Clip.none, children: [
                  Icon(Icons.notifications),
                  if (unreadCount > 0)
                    Positioned(
                      right: -5,
                      top: -8,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.red,
                        child: Text(
                          unreadCount.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ]),
                tooltip: "Notifications",
                itemBuilder: (context) {
                  List<PopupMenuEntry> items = [];
                  items.add(PopupMenuItem(
                    enabled: false,
                    padding: EdgeInsets.zero,
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: 200,
                            maxHeight: 400,
                          ),
                          child: dataManager.notifications.take(10).isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text('No notifications'),
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: dataManager.notifications
                                        .take(10)
                                        .map((notif) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 10),
                                        child: InkWell(
                                          onTap: () {
                                            if (notif.referenceID != null) {
                                              Navigator.pop(
                                                  context); // Close menu first
                                              handleNotificationRedirect(
                                                  context,
                                                  dataManager,
                                                  widget.session!,
                                                  notif);
                                            }
                                          },
                                          child: NotificationTile(
                                              notification: notif),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                        );
                      },
                    ),
                  ));

                  items.add(const PopupMenuDivider());

                  items.add(
                    PopupMenuItem(
                      enabled: false,
                      child: Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NotificationsPage(
                                  session: widget.session!,
                                ),
                              ),
                            );
                          },
                          child: Text('See all notifications'),
                        ),
                      ),
                    ),
                  );

                  return items;
                },
              ),
              IconButton(
                icon: Icon(Icons.logout),
                tooltip: "Logout",
                onPressed: _logout,
              ),
            ],
          ),
          drawer: Drawer(
            backgroundColor: kPrimaryContainer,
            child: Column(
              children: <Widget>[
                UserAccountsDrawerHeader(
                  accountName: Text(widget.session!.user.username),
                  accountEmail: Text(
                      "${widget.session!.user.firstName} ${widget.session!.user.lastName}"),
                  decoration: BoxDecoration(color: kPrimary),
                  currentAccountPicture: CircleAvatar(
                    child: Icon(Icons.person, size: 40),
                  ),
                ),
                _buildDrawerItem(Icons.dashboard, "Dashboard", 0),
                _buildDrawerItem(Icons.message_outlined, "Chatrooms", 1),
                _buildDrawerItem(Icons.list, "Tickets", 2),
                _buildDrawerItem(Icons.question_mark, "FAQ", 3),
                if (widget.session?.user.role != "Employee")
                  _buildDrawerItem(Icons.stacked_bar_chart, "Reports", 4),
                if (widget.session?.user.role == "Admin")
                  _buildDrawerItem(Icons.person_outline, "User Management", 5),
                if (widget.session?.user.role == "Admin")
                  _buildDrawerItem(Icons.settings, "Settings", 6),
              ],
            ),
          ),
          body: widget.child);
    });
  }

  /// **Dynamic AppBar Title**
  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return "Dashboard";
      case 1:
        return "Chatroom";
      case 2:
        return "Tickets";
      case 3:
        return "FAQ";
      case 4:
        return "Reports";
      case 5:
        return "User Management";
      case 6:
        return "Settings";
      default:
        return "Dashboard";
    }
  }

  /// **Drawer Item Builder with Highlighting**
  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon,
          color: _selectedIndex == index ? Colors.blue : Colors.black),
      title: Text(title,
          style: TextStyle(
              color: _selectedIndex == index ? Colors.blue : Colors.black)),
      tileColor: _selectedIndex == index ? Colors.blue.withOpacity(0.2) : null,
      onTap: () => _onDrawerItemTapped(index),
    );
  }
}
