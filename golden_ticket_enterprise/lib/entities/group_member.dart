
import 'package:golden_ticket_enterprise/entities/user.dart';

class GroupMember{
  final User? member;
  final DateTime? joinedAt;
  DateTime? lastSeenAt;
  GroupMember({required this.member, required this.joinedAt, required this.lastSeenAt});
  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
        member: User.fromJson(json['user']),
        joinedAt: DateTime.parse(json['joinedAt']),
        lastSeenAt: json['lastSeenAt'] != null ? DateTime.parse(json['lastSeenAt']) : null
    );
  }
}