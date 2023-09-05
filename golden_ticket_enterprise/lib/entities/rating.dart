
import 'package:golden_ticket_enterprise/entities/chatroom.dart';

class Rating {
  final int ratingID;
  Chatroom chatroom;
  int score;
  String? feedback;
  DateTime createdAt;
  Rating({ required this.ratingID, required this.chatroom, required this.score, required this.feedback, required this.createdAt});

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      ratingID: json['ratingID'],
      chatroom: Chatroom.fromJson(json['chatroom']),
      score: json['score'],
      feedback: json['feedback'] ?? 'None Provided',
      createdAt: DateTime.parse(json['createdAt'])
    );
  }

}