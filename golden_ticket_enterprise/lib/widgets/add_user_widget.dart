import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/config.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:golden_ticket_enterprise/widgets/notification_widget.dart';
import 'package:provider/provider.dart';

class AddUserWidget extends StatefulWidget {
  @override
  _AddUserWidgetState createState() => _AddUserWidgetState();
}

class _AddUserWidgetState extends State<AddUserWidget> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  String? _selectedRole;
  Map<String, bool> _tagSelectionMap = {};
  bool _isSaving = false;

  List<String> get selectedTags => _selectedRole != 'Employee'
      ? _tagSelectionMap.entries.where((e) => e.value).map((e) => e.key).toList()
      : [];

  void _addUser(BuildContext context, DataManager dataManager) async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final firstName = _firstNameController.text.trim();
    final middleName = _middleNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (username.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        firstName.isEmpty ||
        lastName.isEmpty ||
        _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    dataManager.signalRService.addUser(
      username,
      password,
      firstName,
      middleName,
      lastName,
      _selectedRole!,
      selectedTags,
    );
    TopNotification.show(
        context: context,
        message: "Successfully added user!",
        backgroundColor: Colors.greenAccent,
        duration: Duration(seconds: 2),
        textColor: Colors.white,
        onTap: () {
          TopNotification.dismiss();
        }
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add User"),
        backgroundColor: kPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<DataManager>(
          builder: (context, dataManager, child) {
            final roles = rolesData;
            final tags = dataManager.mainTags;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username *'),
                  ),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password *'),
                  ),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Retype Password *'),
                  ),
                  TextField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name *'),
                  ),
                  TextField(
                    controller: _middleNameController,
                    decoration: const InputDecoration(labelText: 'Middle Name (optional)'),
                  ),
                  TextField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name *'),
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    hint: const Text('Select Role *'),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedRole = newValue;
                      });
                    },
                    items: roles.map((role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                  ),
                  if (_selectedRole != 'Employee')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: tags.map((tag) {
                        return CheckboxListTile(
                          title: Text(tag.tagName),
                          value: _tagSelectionMap[tag.tagName] ?? false,
                          onChanged: (bool? value) {
                            setState(() {
                              _tagSelectionMap[tag.tagName] = value ?? false;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children:[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        onPressed: _isSaving ? null : () => _addUser(context, dataManager),
                        child: _isSaving
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text('Add User', style: TextStyle(color: Colors.white)),
                      ),
                    ]
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
