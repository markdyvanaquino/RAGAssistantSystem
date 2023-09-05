import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:provider/provider.dart';

class FaqSuggestionTab extends StatefulWidget {
  final HiveSession session;
  const FaqSuggestionTab({super.key, required this.session});

  @override
  State<FaqSuggestionTab> createState() => _FaqSuggestionTabState();
}

class _FaqSuggestionTabState extends State<FaqSuggestionTab> {
  List<MapEntry<String, int>> topSuggestions = [];
  List<MapEntry<String, int>> topRequested = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dataManager = Provider.of<DataManager>(context);
    _processData(dataManager);
  }

  void _processData(DataManager dataManager) {
    final tickets = dataManager.tickets;
    final faqs = dataManager.faqs;

    final existingFaqTags = faqs
        .map((f) => '${f.mainTag?.tagName}-${f.subTag?.subTagName}')
        .toSet();

    final tagPairs = <String, int>{};
    for (var ticket in tickets) {
      if (ticket.mainTag != null && ticket.subTag != null) {
        final key = '${ticket.mainTag?.tagName}-${ticket.subTag?.subTagName}';
        tagPairs[key] = (tagPairs[key] ?? 0) + 1;
      }
    }

    final suggestions = tagPairs.entries
        .where(
            (entry) => !existingFaqTags.contains(entry.key) && entry.value == 5)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final requested = tagPairs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      topSuggestions = suggestions;
      topRequested = requested.take(10).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(builder: (context, dataManager, child) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('📖 FAQ Suggestions'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              _buildSectionCard(
                icon: Icons.lightbulb_outline,
                iconColor: Colors.amber[700],
                title: "Suggested FAQs (Not Yet Created)",
                children: topSuggestions.map((entry) {
                  final parts = entry.key.split('-');
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const Icon(Icons.help_outline, color: Colors.blue),
                      title: Text(
                        parts[0],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(parts[1]),
                      trailing: Chip(
                        label: Text('${entry.value} requests'),
                        backgroundColor: Colors.blue.shade100,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              _buildSectionCard(
                icon: Icons.trending_up,
                iconColor: Colors.redAccent,
                title: "Most Requested Tags",
                children: topRequested.map((entry) {
                  final parts = entry.key.split('-');
                  return ListTile(
                    leading: const Icon(Icons.label_important, color: Colors.red),
                    title: Text(
                      parts[0],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(parts[1]),
                    trailing: Text(
                      '${entry.value}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color? iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
