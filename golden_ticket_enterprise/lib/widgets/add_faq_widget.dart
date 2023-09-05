import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/main_tag.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:provider/provider.dart';

class AddFAQDialog extends StatefulWidget {
  final Function(String title, String description, String solution, String mainTag, String subTag) onSubmit;

  const AddFAQDialog({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<AddFAQDialog> createState() => _AddFAQDialogState();
}

class _AddFAQDialogState extends State<AddFAQDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController solutionController = TextEditingController();

  String? selectedMainTag;
  String? selectedSubTag;

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        List<MainTag> mainTags = dataManager.mainTags;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Add FAQ', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.white),
                                tooltip: 'Close',
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),

                            _buildTextField(titleController, "Title", 1, 100),
                            _buildTextField(descriptionController, "Description", 3, 300),
                            _buildTextField(solutionController, "Solution", 3, 1200),

                            _buildDropdown(
                              "Select Main Tag",
                              selectedMainTag,
                              mainTags.map((tag) => tag.tagName).toList(),
                                  (value) {
                                setState(() {
                                  selectedMainTag = value;
                                  selectedSubTag = null;
                                });
                              },
                            ),

                            _buildDropdown(
                              "Select Sub Tag",
                              selectedSubTag,
                              selectedMainTag == null
                                  ? []
                                  : mainTags
                                  .firstWhere((tag) => tag.tagName == selectedMainTag)
                                  .subTags
                                  .map((subTag) => subTag.subTagName)
                                  .toList(),
                                  (value) {
                                setState(() {
                                  selectedSubTag = value;
                                });
                              },
                            ),

                            const SizedBox(height: 20),

                            Align(
                              alignment: Alignment.centerRight,
                              child: Wrap(
                                spacing: 8,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Cancel"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        widget.onSubmit(
                                          titleController.text,
                                          descriptionController.text,
                                          solutionController.text,
                                          selectedMainTag!,
                                          selectedSubTag!,
                                        );
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: const Text("Add FAQ"),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, int maxLines, int maxChar) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxChar,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        validator: (value) => value == null || value.trim().isEmpty ? 'This field is required' : null,
      ),
    );
  }

  Widget _buildDropdown(String hint, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(hint),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Please select a value' : null,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}
