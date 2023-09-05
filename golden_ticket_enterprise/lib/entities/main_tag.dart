
import 'package:golden_ticket_enterprise/entities/sub_tag.dart';

class MainTag {
  final int tagID;
  final String tagName;
  final List<SubTag> subTags;

  MainTag({required this.tagID, required this.tagName, required this.subTags});

  factory MainTag.fromJson(Map<String, dynamic> json) {
    List<SubTag> subTags = [];
    if(json['subTags'] != null) {
      for (var data in json['subTags']) {
        subTags.add(SubTag.fromJson(data));
      }
    }
    return MainTag(
        tagID: json['mainTagID'],
        tagName: json['mainTagName'] ?? "",
        subTags: subTags
      );
  }

  Map<String, dynamic> toJson() {
    return {
      'mainTagID': tagID,
      'mainTagName': tagName,
      'subTags': subTags,
    };
  }

}