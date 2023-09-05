import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:golden_ticket_enterprise/entities/faq.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:golden_ticket_enterprise/widgets/add_faq_widget.dart';
import 'package:golden_ticket_enterprise/widgets/edit_faq_widget.dart';
import 'package:golden_ticket_enterprise/widgets/notification_widget.dart';
import 'package:golden_ticket_enterprise/widgets/related_ticket_widget.dart';
import 'package:provider/provider.dart';

class FAQPage extends StatefulWidget {
  final HiveSession? session;

  FAQPage({super.key, required this.session});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  String searchQuery = "";
  String? selectedMainTag = "All";
  String? selectedSubTag;

  final ScrollController _scrollController = ScrollController();
  int _itemsPerPage = 10;
  int _currentMaxItems = 10;
  late DataManager dm;
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
        setState(() {
          _currentMaxItems += _itemsPerPage;
        });
      }
    });
    dm = Provider.of<DataManager>(context, listen: false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {

        List<FAQ> filteredFAQs = dataManager.faqs.where((faq) {
          bool matchesSearch = searchQuery.isEmpty || faq.title.toLowerCase().contains(searchQuery.toLowerCase());
          bool matchesMainTag = selectedMainTag == "All" || faq.mainTag?.tagName == selectedMainTag;
          bool matchesSubTag = selectedSubTag == null || faq.subTag?.subTagName == selectedSubTag;
          bool includeArchived = widget.session?.user.role != "Employee" || faq.isArchived == false;
          return matchesSearch && matchesMainTag && matchesSubTag && includeArchived;
        }).toList();

        List<FAQ> displayedFAQs = filteredFAQs.take(_currentMaxItems).toList();

        void addFAQ(String title, String description, String solution, String mainTag, String subTag) {
          setState(() {
            dataManager.signalRService.addFAQ(title, description, solution, mainTag, subTag);
          });
        }

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            heroTag: "add_faq",
            tooltip: widget.session!.user.role == "Employee" ? "Request Chat" : "Add FAQ",
            onPressed: () {
              if (widget.session!.user.role == "Employee" && !dataManager.disableRequest) {
                dataManager.disableRequestButton();
                dataManager.signalRService.requestChat(widget.session!.user.userID);
              } else {
                showDialog(
                  context: context,
                  builder: (context) => AddFAQDialog(
                    onSubmit: addFAQ,
                  ),
                );
              }
            },

            child: Icon(widget.session!.user.role == "Employee" ? Icons.chat : Icons.add),
            backgroundColor: widget.session!.user.role == "Employee" ? Colors.blueAccent : kPrimary,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                      _currentMaxItems = _itemsPerPage; // Reset pagination on new search
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search FAQs...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(height: 10),
                // Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedMainTag,
                        hint: Text("Main Tag"),
                        items: ["All", ...dataManager.mainTags.map((tag) => tag.tagName)].map((tag) {
                          return DropdownMenuItem(
                            value: tag,
                            child: Text(tag),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedMainTag = value;
                            selectedSubTag = null;
                            _currentMaxItems = _itemsPerPage; // Reset pagination on filter change
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedSubTag,
                        hint: selectedMainTag == 'All' ? Text('Select a main tag first...') : Text("Select a Sub tag..."),
                        items: dataManager.mainTags
                            .where((tag) => tag.tagName == selectedMainTag)
                            .expand((tag) => tag.subTags.map((subTag) => subTag.subTagName))
                            .map((subTag) => DropdownMenuItem(
                          value: subTag,
                          child: Text(subTag),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedSubTag = value;
                            _currentMaxItems = _itemsPerPage; // Reset pagination on filter change
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                // FAQ List
                Expanded(
                  child: filteredFAQs.isEmpty
                      ? Center(
                    child: Text(
                      "No FAQs found",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  )
                      : ListView.builder(
                    controller: _scrollController,
                    itemCount: displayedFAQs.length + (filteredFAQs.length > displayedFAQs.length ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == displayedFAQs.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      var faq = displayedFAQs[index];
                      return ExpansionTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                faq.title,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        subtitle: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 300) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (faq.mainTag != null)
                                    Chip(
                                      backgroundColor: Colors.redAccent,
                                      label: Text(faq.mainTag!.tagName, style: TextStyle(fontWeight: FontWeight.bold, color: kSurface)),
                                    ),
                                  if (faq.subTag != null)
                                    Chip(
                                      backgroundColor: Colors.blueAccent,
                                      label: Text(faq.subTag!.subTagName, style: TextStyle(fontWeight: FontWeight.bold, color: kSurface)),
                                    ),
                                ],
                              );
                            } else {
                              return Row(
                                children: [
                                  if (faq.mainTag != null)
                                    Chip(
                                      backgroundColor: Colors.redAccent,
                                      label: Text(faq.mainTag!.tagName, style: TextStyle(fontWeight: FontWeight.bold, color: kSurface)),
                                    ),
                                  SizedBox(width: 5),
                                  if (faq.subTag != null)
                                    Chip(
                                      backgroundColor: Colors.blueAccent,
                                      label: Text(faq.subTag!.subTagName, style: TextStyle(fontWeight: FontWeight.bold, color: kSurface)),
                                    ),
                                ],
                              );
                            }
                          },
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MarkdownBody(
                                  data: faq.description,
                                  selectable: true,
                                ),
                                SizedBox(height: 8),
                                SelectableText(
                                  "Solution:",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                MarkdownBody(
                                  data: faq.solution,
                                  selectable: true,
                                ),
                                SizedBox(height: 8),
                                if (widget.session!.user.role != "Employee")
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => FAQEditWidget(faq: faq),
                                          );
                                        },
                                        child: Text("Edit"),
                                      ),
                                      SizedBox(width: 10),
                                      if(widget.session!.user.role != 'Employee')ElevatedButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => RelatedTicketWidget(session: widget.session!, mainTag: faq.mainTag!.tagName, subTag: faq.subTag!.subTagName)
                                          );
                                        },
                                        child: Text("View Ticket Related"),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
