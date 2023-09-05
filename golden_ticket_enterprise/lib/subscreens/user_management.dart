import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/user.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/widgets/add_user_widget.dart';
import 'package:golden_ticket_enterprise/widgets/edit_user_widget.dart';
import 'package:provider/provider.dart';

class UserManagementPage extends StatefulWidget {
  final HiveSession? session;
  const UserManagementPage({super.key, required this.session});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<DataManager>(
        builder: (context, dataManager, child) {
          List<User> admins = dataManager.getAdmins();
          List<User> agents = dataManager.getAgents();
          List<User> employees = dataManager.getEmployees();
          List<User> disabledUsers = dataManager.getDisabledUsers(); // Assuming method

          // Combine all users and filter
          List<User> filteredAdmins = _filterUsers(admins);
          List<User> filteredAgents = _filterUsers(agents);
          List<User> filteredEmployees = _filterUsers(employees);
          List<User> filteredDisabled = _filterUsers(disabledUsers);

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search users by name, role, or tag...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                    });
                  },
                ),
              ),
              _buildUserSection(context, 'Admin', filteredAdmins),
              _buildUserSection(context, 'Staff/Agent', filteredAgents),
              _buildUserSection(context, 'Employees', filteredEmployees),
              _buildUserSection(context, 'Disabled Users', filteredDisabled), // Disabled Users section
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "add_user",
        tooltip: 'Add User',
        onPressed: () {
          showDialog(context: context, builder: (context) => AddUserWidget());
        },
        child: Icon(Icons.person_add),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
      ),
    );
  }

  List<User> _filterUsers(List<User> users) {
    if (_searchQuery.isEmpty) return users;

    return users.where((user) {
      final fullName =
      '${user.firstName} ${user.middleName ?? ''} ${user.lastName}'
          .toLowerCase();
      final role = user.role.toLowerCase() ?? '';
      final tags = user.assignedTags?.join(' ').toLowerCase() ?? '';

      return fullName.contains(_searchQuery) ||
          role.contains(_searchQuery) ||
          tags.contains(_searchQuery);
    }).toList();
  }

  Widget _buildUserSection(
      BuildContext context, String title, List<User> users) {
    if (users.isEmpty) return SizedBox(); // Hide empty sections

    return ExpansionTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      children: [
        ...users.map((user) {
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Row(
                children: [
                  Text(
                      '${user.firstName} ${user.middleName ?? ''} ${user.lastName}'),
                  SizedBox(width: 10),
                  Chip(
                    label: Text('${user.role}'),
                    backgroundColor: Colors.orangeAccent,
                  )
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => EditUserWidget(user: user, session: widget.session!,),
                  );
                },
              ),
              isThreeLine: true,
              contentPadding: EdgeInsets.all(16),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user.assignedTags != null &&
                      user.assignedTags!.isNotEmpty)
                    Wrap(
                      spacing: 8.0,
                      children: [
                        ...user.assignedTags!.take(3).map((tag) {
                          return Chip(
                            label: Text(tag,
                                style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.redAccent,
                          );
                        }).toList(),
                        if (user.assignedTags!.length > 3)
                          Tooltip(
                            message: '${user.assignedTags!.skip(3).join(', ')}',
                            child: Chip(
                              label: Text(
                                  "+${user.assignedTags!.length - 3} more",
                                  style: TextStyle(color: Colors.white)),
                              backgroundColor: Colors.blueAccent,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
