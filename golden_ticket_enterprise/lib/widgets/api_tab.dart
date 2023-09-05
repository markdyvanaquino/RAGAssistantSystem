import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/apikey.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/string_utils.dart';
import 'package:golden_ticket_enterprise/models/time_utils.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';

class ApiKeysTab extends StatefulWidget {
  final DataManager dataManager;

  const ApiKeysTab({Key? key, required this.dataManager}) : super(key: key);

  @override
  State<ApiKeysTab> createState() => _ApiKeysTabState();
}

class _ApiKeysTabState extends State<ApiKeysTab> {
  String selectedFilter = 'All';

  void _showApiKeyDialog({ApiKey? apiKey, int? index}) {
    final keyController = TextEditingController(text: apiKey?.apiKey ?? '');
    final noteController = TextEditingController(text: apiKey?.note ?? '');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    Text('${apiKey == null ? 'Add Api Key': 'Edit Api Key'}', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: keyController, decoration: InputDecoration(labelText: "API Key")),
                    const SizedBox(height: 10),
                    TextField(controller: noteController, decoration: InputDecoration(labelText: "Note")),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onPressed: ()  {
                            final key = keyController.text.trim();
                            final note = noteController.text.trim();
                            if (key.isNotEmpty) {
                              setState(() {
                                if (apiKey == null) {
                                  widget.dataManager.signalRService.addAPIKey(key, note);
                                } else if (index != null) {
                                  widget.dataManager.signalRService.updateAPIKey(apiKey.apiKeyID, key, note);
                                }
                              });
                              Navigator.pop(context);
                            }
                          },
                          child: Text('Save', style: TextStyle(color: Colors.white),),
                        ),
                      ],
                    )
                  ]
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataManager = widget.dataManager;

    // Filtered list based on dropdown
    final filteredKeys = dataManager.apiKeys.where((apiKey) {
      final isRateLimited = apiKey.lastRateLimit != null &&
          DateTime.now().difference(apiKey.lastRateLimit!).inHours < 24;

      switch (selectedFilter) {
        case 'Rate Limited':
          return isRateLimited;
        case 'Available':
          return !isRateLimited;
        case 'All':
        default:
          return true;
      }
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedFilter,
                  padding: EdgeInsets.only(top: 5),
                  decoration: InputDecoration(
                    labelText: 'Availability',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  items: ['All', 'Available', 'Rate Limited'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedFilter = value!;
                    });
                  }, // Disable dropdown if needed
                  disabledHint: Text('Availability', style: TextStyle(color: Colors.grey)), // Greyed-out label
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showApiKeyDialog(),
                icon: const Icon(Icons.add),
                label: const Text("Add API Key"),
              ),
            ],
          ),
          const SizedBox(height: 10),
          filteredKeys.isEmpty
              ? const Center(child: Text("No API Keys", style: TextStyle(color: Colors.grey)))
              : Expanded(
            child: ListView.builder(
              itemCount: filteredKeys.length,
              itemBuilder: (context, index) {
                var apiKey = filteredKeys[index];
                var isRateLimited = apiKey.lastRateLimit != null &&
                    DateTime.now().difference(apiKey.lastRateLimit!).inHours < 24;

                return Card(
                  child: ListTile(
                    tileColor: kSecondaryContainer,
                    subtitle: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(title: Text(StringUtils.filterApiKey(apiKey.apiKey)), subtitle: Text(StringUtils.limitWithEllipsis(apiKey.note ?? 'No note', 25)), leading: Icon(Icons.vpn_key)),
                        if(isRateLimited)
                          Chip(
                            label: Text(
                              'Rate Limited ${apiKey.lastRateLimit != null ? TimeUtil.formatTimestamp(apiKey.lastRateLimit!) : ''}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        ListTile(title: Text('${apiKey.usage}'), leading: Icon(Icons.energy_savings_leaf))
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showApiKeyDialog(apiKey: apiKey, index: index);
                        } else if (value == 'delete') {
                          setState(() {
                            widget.dataManager.signalRService.deleteAPIKey(apiKey.apiKeyID);
                          });
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
