import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/entities/main_tag.dart';

class TagsTab extends StatefulWidget {
  final DataManager dataManager;

  const TagsTab({Key? key, required this.dataManager}) : super(key: key);

  @override
  State<TagsTab> createState() => _TagsTabState();
}

class _TagsTabState extends State<TagsTab> {
  final TextEditingController _mainTagController = TextEditingController();
  final TextEditingController _subTagController = TextEditingController();
  String? selectedMainTag;

  void _addMainTag() {
    final tagName = _mainTagController.text.trim();
    if (tagName.isNotEmpty) {
      widget.dataManager.signalRService.addMainTag(tagName);
      _mainTagController.clear();
    }
  }

  void _addSubTag() {
    final subTagName = _subTagController.text.trim();
    if (subTagName.isNotEmpty && selectedMainTag != null) {
      final mainTag = widget.dataManager.mainTags.firstWhere(
            (tag) => tag.tagName == selectedMainTag,
        orElse: () => MainTag(tagID: -1, tagName: '', subTags: []),
      );
      if (mainTag.tagID != -1) {
        widget.dataManager.signalRService.addSubTag(subTagName, mainTag.tagName);
        _subTagController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = widget.dataManager;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Add Main Tag", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mainTagController,
                    decoration: InputDecoration(
                      hintText: "Enter main tag",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _addMainTag,
                  icon: const Icon(Icons.add),
                  label: const Text("Add"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text("Add Sub Tag", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedMainTag,
              hint: const Text("Select Main Tag"),
              items: dataManager.mainTags.map((tag) {
                return DropdownMenuItem(
                  value: tag.tagName,
                  child: Text(tag.tagName),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedMainTag = value),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subTagController,
                    decoration: InputDecoration(
                      hintText: "Enter sub tag",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _addSubTag,
                  icon: const Icon(Icons.add),
                  label: const Text("Add"),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text("Available Tags", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            dataManager.mainTags.isEmpty
                ? const Center(child: Text("No tags available", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dataManager.mainTags.length,
              itemBuilder: (context, index) {
                final mainTag = dataManager.mainTags[index];
                return Card(
                  child: ExpansionTile(
                    title: Text(mainTag.tagName),
                    children: mainTag.subTags.isEmpty
                        ? [const ListTile(title: Text("No sub-tags"))]
                        : mainTag.subTags.map((subTag) => ListTile(title: Text(subTag.subTagName))).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
