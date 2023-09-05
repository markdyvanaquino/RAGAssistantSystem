import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/chatroom.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/models/time_utils.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:hive_flutter/adapters.dart';

class ChatroomDetailsDrawer extends StatelessWidget {
  final Chatroom chatroom;
  final DataManager dataManager;

  const ChatroomDetailsDrawer({Key? key, required this.chatroom, required this.dataManager})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var userSession = Hive.box<HiveSession>('sessionBox').get('user');

    return Drawer(
      backgroundColor: kPrimaryContainer,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: kPrimary),
            child: Text(
              '${chatroom.author.firstName} ${chatroom.author.lastName}',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Created By"),
            subtitle: Text(
                '${chatroom.author.firstName} ${chatroom.author.lastName}' ??
                    "Unknown"),
          ),
          ExpansionTile(
            leading: const Icon(Icons.confirmation_number),
            title: const Text("Ticket"),
            subtitle: Text(
                '${chatroom.ticket != null ? 'Ticket ID: ${chatroom.ticket!.ticketID}' : 'No Ticket'}'),
            children: [
              if (chatroom.ticket != null)
                ListTile(
                    title: const Text("Ticket Title:"),
                    subtitle: Text(
                        '${chatroom.ticket?.ticketTitle ?? "No Title Provided"}')),
              if (chatroom.ticket != null && chatroom.ticket?.assigned != null)
                ListTile(
                    title: const Text("Assigned Agent:"),
                    subtitle: Text('${chatroom.ticket!.assigned!.firstName}')),
              if (chatroom.ticket != null)
                ListTile(
                  title: const Text("Priority:"),
                  subtitle: Row(children: [
                    Chip(
                        backgroundColor:
                            getPriorityColor(chatroom.ticket!.priority!),
                        label: Text(
                          chatroom.ticket!.priority!,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: kSurface),
                        ))
                  ]),
                ),
              if (chatroom.ticket != null)
                ListTile(
                  title: const Text("Status:"),
                  subtitle: Row(children: [
                    Chip(
                        backgroundColor:
                            getStatusColor(chatroom.ticket!.status),
                        label: Text(
                          chatroom.ticket!.status,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: kSurface),
                        ))
                  ]),
                ),
              if (chatroom.ticket != null)
                ListTile(
                    title: const Text("Tags:"),
                    subtitle: Column(
                      children: [
                        Chip(
                            backgroundColor: Colors.redAccent,
                            label: Text(
                              chatroom.ticket!.mainTag?.tagName ??
                                  "No Main Tag Provided",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: kSurface),
                            )),
                        Chip(
                            backgroundColor: Colors.blueAccent,
                            label: Text(
                              chatroom.ticket!.subTag?.subTagName ??
                                  "No Sub Tag Provided",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: kSurface),
                            )),
                      ],
                    ))
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.people),
            title: const Text("Members"),
            subtitle: Text("${chatroom.groupMembers!.length} members"),
            children: chatroom.groupMembers!.map((member) {
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(
                    "${member.member!.firstName} ${member.member!.lastName}"),
                subtitle: Text(TimeUtil.formatCreationDate(member.joinedAt!)),
              );
            }).toList(),
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text("Date Created"),
            subtitle:
                Text(TimeUtil.formatCreationDate(chatroom.createdAt.toLocal())),
          ),
          if (!chatroom.isClosed && (chatroom.groupMembers?.any((member) => member.member?.userID == userSession!.user.userID) ?? false))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextButton(
                onPressed: () {
                  if(chatroom.ticket != null) {
                    dataManager.signalRService.updateTicket(
                        chatroom.ticket!.ticketID,
                        chatroom.ticket!.ticketTitle,
                        'Closed',
                        chatroom.ticket!.priority,
                        chatroom.ticket!.mainTag?.tagName,
                        chatroom.ticket!.subTag?.subTagName,
                        chatroom.ticket!.assigned?.userID);
                  }else{
                    dataManager.signalRService.closeChatroom(chatroom.chatroomID);
                  }
                },
                child: const Text(
                  'Close Chatroom',
                  style: TextStyle(
                    color: Colors.red, // text color like FlatButton
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}
