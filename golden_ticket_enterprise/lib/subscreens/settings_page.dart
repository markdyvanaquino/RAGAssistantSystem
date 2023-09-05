import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:golden_ticket_enterprise/widgets/api_tab.dart';
import 'package:golden_ticket_enterprise/widgets/notification_widget.dart';
import 'package:golden_ticket_enterprise/widgets/tags_tab.dart';
import 'package:provider/provider.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/entities/main_tag.dart';

class SettingsPage extends StatefulWidget {
  final HiveSession? session;

  SettingsPage({super.key, required this.session});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 2 tabs: Tags, API Keys
      child: Consumer<DataManager>(
        builder: (context, dataManager, child) {
          dataManager.signalRService.onExistingTag = () {
            TopNotification.show(
              context: context,
              message: "The tag that you're trying to add is already existing!",
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 2),
              textColor: Colors.white,
              onTap: () {
                TopNotification.dismiss();
              },
            );
          };

          return Scaffold(
            appBar: AppBar(
              title: TabBar(
                tabs: [
                  Tab(text: 'Tags'),
                  Tab(text: 'API Keys'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                TagsTab(dataManager: dataManager),
                ApiKeysTab(dataManager: dataManager),
              ]
            ),
          );
        },
      ),
    );
  }
}
