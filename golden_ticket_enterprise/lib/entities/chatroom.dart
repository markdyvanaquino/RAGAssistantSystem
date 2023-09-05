
import 'package:golden_ticket_enterprise/entities/group_member.dart';
import 'package:golden_ticket_enterprise/entities/message.dart';
import 'package:golden_ticket_enterprise/entities/ticket.dart';
import 'package:golden_ticket_enterprise/entities/user.dart';

class Chatroom {
  final int chatroomID;
  String chatroomName;
  final User author;
  Ticket? ticket;
  List<Message>? messages = [];
  LastMessage? lastMessage;
  List<GroupMember>? groupMembers;
  int unread;
  DateTime createdAt;
  bool isClosed;
  Chatroom({required this.chatroomID, required this.chatroomName, required this.unread, required this.isClosed, required this.author, this.ticket, required this.createdAt, required this.messages, required this.groupMembers, required this.lastMessage});

  factory Chatroom.fromJson(Map<String, dynamic> json) {
    List<Message> msgs = [];
    List<GroupMember> members = [];

    // Ensure 'groupMembers' exists and is a List
    if (json['groupMembers'] != null && json['groupMembers'] is List) {
      for (var member in json['groupMembers']) {
        members.add(GroupMember.fromJson(member));
      }
    }

    // Ensure 'messages' exists and is a List
    if (json['messages'] != null && json['messages'] is List) {
      for (var msg in json['messages']) {
        msgs.add(Message.fromJson(msg));

        msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }
    }

    return Chatroom(
      chatroomID: json['chatroomID'],
      author: User.fromJson(json['author']),
      createdAt: DateTime.parse(json['createdAt']),
      chatroomName: json['chatroomName'],
      messages: msgs.isNotEmpty ? msgs : [], // Ensure it never remains null
      groupMembers: members.isNotEmpty ? members : [], // Ensure it never remains null
      lastMessage: json['lastMessage'] != null ? LastMessage.fromJson(json['lastMessage']) : null,
      ticket: json['ticket'] != null ? Ticket.fromJson(json['ticket']) : null,
      unread: json['unread'],
      isClosed: json['isClosed']
    );

  }

}

class LastMessage{
  String? messageContent;
  User? sender;
  DateTime? createdAt;
  LastMessage({required this.messageContent, required this.sender, required this.createdAt});
  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      messageContent: json['lastMessage'] ?? "", // Ensure a fallback value
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

}