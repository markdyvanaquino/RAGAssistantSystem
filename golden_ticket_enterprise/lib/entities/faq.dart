import 'package:golden_ticket_enterprise/entities/main_tag.dart';
import 'package:golden_ticket_enterprise/entities/sub_tag.dart';

class FAQ {
  final int faqID;
  final String title;
  final String description;
  final String solution;
  final DateTime createdAt;
  final bool isArchived;
  MainTag? mainTag;
  SubTag? subTag;
  FAQ({ required this.faqID, required this.title, required this.description, required this.solution, required this.createdAt, required this.isArchived, this.mainTag, this.subTag});

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
        faqID: json['faqID'],
        title: json['title'],
        description: json['description'],
        solution:  json['solution'],
        createdAt: DateTime.parse(json['createdAt']),
        isArchived: json['isArchived'],
        mainTag: MainTag.fromJson(json['mainTag']),
        subTag: SubTag.fromJson(json['subTag'])
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'faqID': faqID,
      'title': title,
      'description': description,
      'solution':  solution,
      'createdAt': createdAt,
      'isArchived': isArchived,
      'mainTag': mainTag,
      'subTag': subTag
    };
  }

}