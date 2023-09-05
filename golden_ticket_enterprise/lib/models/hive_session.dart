import 'package:hive/hive.dart';
import 'user.dart';

part 'hive_session.g.dart'; // Hive adapter file

@HiveType(typeId: 2) // Ensure a unique type ID
class HiveSession extends HiveObject {
  @HiveField(0)
  final User user;

  @HiveField(1)
  final String sessionExpiryAt;

  HiveSession({
    required this.user,
    required this.sessionExpiryAt,
  });

  factory HiveSession.fromJson(Map<String, dynamic> json) {
    return HiveSession(
      user: User.fromJson(json['user']),
      sessionExpiryAt: json['sessionExpiry'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'sessionExpiry': sessionExpiryAt,
    };
  }
}
