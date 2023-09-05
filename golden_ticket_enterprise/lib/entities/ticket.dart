
import 'package:golden_ticket_enterprise/entities/main_tag.dart';
import 'package:golden_ticket_enterprise/entities/sub_tag.dart';
import 'package:golden_ticket_enterprise/entities/ticket_history.dart';
import 'package:golden_ticket_enterprise/entities/user.dart';

class Ticket {
  final int ticketID;
  final String ticketTitle;
  final User author;
  User? assigned;
  final String status;
  String priority;
  MainTag? mainTag;
  SubTag? subTag;
  List<TicketHistory>? ticketHistory = [];
  final DateTime createdAt;
  DateTime? deadlineAt;

  Ticket({ required this.ticketID, required this.ticketTitle, required this.priority, required this.author, this.ticketHistory, this.assigned, required this.status, this.mainTag, this.subTag, required this.createdAt, this.deadlineAt});

  factory Ticket.fromJson(Map<String, dynamic> json) {
    List<TicketHistory> tHistory = [];
    for(var history in json['ticketHistory']){
      tHistory.add(TicketHistory.fromJson(history));
    }

    return Ticket(
      ticketID: json['ticketID'],
      ticketTitle: json['ticketTitle'] == null ? "None Provided" : json['ticketTitle'],
      mainTag: json['mainTag'] == null ? null : MainTag.fromJson(json['mainTag']),
      subTag: json['subTag'] == null  ? null : SubTag.fromJson(json['subTag']),
      author: User.fromJson(json['author']),
      status: json['status'],
      priority: json['priority'],
      ticketHistory: tHistory,
      assigned: json['assigned'] == null ? null : User.fromJson(json['assigned']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

}