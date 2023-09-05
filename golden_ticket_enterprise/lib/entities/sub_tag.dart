
import 'package:golden_ticket_enterprise/entities/main_tag.dart';

class SubTag {
  final int subTagID;
  final String subTagName;

  SubTag({ required this.subTagID, required this.subTagName});

  factory SubTag.fromJson(Map<String, dynamic> json) {
    dynamic userData = json;
    return SubTag(
        subTagID: userData['subTagID'],
        subTagName: userData['subTagName'] ?? ""
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subTagID': subTagID,
      'subTagName': subTagName
    };
  }

}