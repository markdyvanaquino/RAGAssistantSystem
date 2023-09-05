import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/config.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:provider/provider.dart';
import 'package:golden_ticket_enterprise/entities/user.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';

class EditUserWidget extends StatefulWidget {
  final User user;
  final HiveSession session;

  const EditUserWidget({super.key, required this.user, required this.session});

  @override
  _EditUserWidgetState createState() => _EditUserWidgetState();
}

class _EditUserWidgetState extends State<EditUserWidget> {
  late TextEditingController _usernameController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  String? _selectedRole;
  Map<String, bool> _tagSelectionMap = {};
  bool _isSaving = false;
  bool _isDisabled = false;
  bool _isTagsDropdownOpen = false;

  List<String> get selectedTags => _selectedRole != 'Employee'
      ? _tagSelectionMap.entries.where((e) => e.value).map((e) => e.key).toList()
      : [];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _firstNameController.text = widget.user.firstName;
    _middleNameController.text = widget.user.middleName ?? '';
    _lastNameController.text = widget.user.lastName;
    _selectedRole = widget.user.role;
    _isDisabled = widget.user.isDisabled;
  }

  Future<void> _initializeTags(DataManager dataManager) async {
    final mainTags = dataManager.mainTags;
    final userTags = widget.user.assignedTags ?? [];

    setState(() {
      for (var tag in mainTags) {
        _tagSelectionMap[tag.tagName] = userTags.contains(tag.tagName);
      }
    });
  }

  void _saveUser(BuildContext context, DataManager dataManager) async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    final password = _passwordController.text.isEmpty ? "" : _passwordController.text;

    dataManager.signalRService.updateUser(
      widget.user.userID,
      widget.user.username,
      password,
      _firstNameController.text,
      _middleNameController.text,
      _lastNameController.text,
      _selectedRole!,
      selectedTags,
      _isDisabled,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, _) {
        if (_tagSelectionMap.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeTags(dataManager);
          });
        }

        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Edit User", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('Account', style: TextStyle(fontWeight: FontWeight.bold)),
                        _buildTextCard([
                          _buildReadOnlyField('Username', _usernameController),
                          _buildPasswordField(),
                        ]),
                        const SizedBox(height: 12),

                        Text('User Information', style: TextStyle(fontWeight: FontWeight.bold)),
                        _buildTextCard([
                          _buildTextField('First Name *', _firstNameController, 75),
                          _buildTextField('Middle Name', _middleNameController, 75),
                          _buildTextField('Last Name *', _lastNameController, 75),
                        ]),
                        const SizedBox(height: 12),

                        Text('Account Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                        _buildTextCard([
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: const InputDecoration(labelText: 'Select Role *'),
                            onChanged: (value) => setState(() => _selectedRole = value),
                            items: rolesData.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                          ),
                          const SizedBox(height: 10),
                          if(widget.session.user.userID != widget.user.userID && widget.user.userID != superAdmingID) SwitchListTile(
                            title: const Text("Account Disabled"),
                            value: _isDisabled,
                            onChanged: (val) => setState(() => _isDisabled = val),
                            activeColor: Colors.redAccent,
                          ),
                          if (_selectedRole != 'Employee') ...[
                            const SizedBox(height: 12),
                            _buildTagSelector(dataManager),
                          ],
                        ]),
                      ],
                    ),
                  ),
                ),

                // Footer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSaving ? null : () => _saveUser(context, dataManager),
                        style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text("Save", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextCard(List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, int maxLength) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        maxLength: maxLength,
      ),
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _passwordController,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'New Password (optional)'),
      ),
    );
  }

  Widget _buildTagSelector(DataManager dataManager) {
    int selectedCount = _tagSelectionMap.values.where((v) => v).length;

    return _buildTextCard([
      GestureDetector(
        onTap: () => setState(() => _isTagsDropdownOpen = !_isTagsDropdownOpen),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(selectedCount == 0 ? 'Assigned Tags' : 'Assigned Tags: $selectedCount selected'),
              Icon(_isTagsDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
      if (_isTagsDropdownOpen)
        ...dataManager.mainTags.map((tag) {
          return CheckboxListTile(
            title: Text(tag.tagName),
            value: _tagSelectionMap[tag.tagName] ?? false,
            onChanged: (val) => setState(() => _tagSelectionMap[tag.tagName] = val ?? false),
          );
        }),
    ]);
  }
}
