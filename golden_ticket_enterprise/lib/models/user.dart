import 'package:hive/hive.dart';

part 'user.g.dart'; // This file will be generated automatically

@HiveType(typeId: 1) // Ensure a unique type ID for this class
class User {
  @HiveField(0)
  final int userID;

  @HiveField(1)
  late final String username;

  @HiveField(2)
  late String firstName;
  @HiveField(3)
  late String middleName;
  @HiveField(4)
  late String lastName;
  @HiveField(5)
  late String role;

  User({
    required this.userID,
    required this.username,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userID: json['userID'],
      username: json['username'],
      firstName: json['firstName'],
      middleName: json['middleName'],
      lastName: json['lastName'],
      role: json['role']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'username': username,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'role': role
    };
  }
}
