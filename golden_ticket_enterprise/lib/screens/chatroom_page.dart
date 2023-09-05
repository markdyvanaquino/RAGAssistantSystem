import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:golden_ticket_enterprise/entities/chatroom.dart';
import 'package:golden_ticket_enterprise/entities/group_member.dart';
import 'package:golden_ticket_enterprise/entities/message.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/models/time_utils.dart';
import 'package:golden_ticket_enterprise/screens/connectionstate.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:golden_ticket_enterprise/widgets/chatroom_details_widget.dart';
import 'package:golden_ticket_enterprise/widgets/notification_widget.dart';
import 'package:golden_ticket_enterprise/widgets/rating_dialog_widget.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

class ChatroomPage extends StatefulWidget {
  final int chatroomID;

  const ChatroomPage({Key? key, required this.chatroomID}) : super(key: key);

  @override
  _ChatroomPageState createState() => _ChatroomPageState();
}

class _ChatroomPageState extends State<ChatroomPage> {
  int? seenMessageID;
  TextEditingController messageController = TextEditingController();
  FocusNode messageFocusNode = FocusNode();
  bool enableMessage = true;
  bool enableRate = true;
  int _messageLimit = 30;

  final ScrollController _scrollController = ScrollController();
  late DataManager dm;
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        // Near the top (because list is reversed)
        setState(() {
          _messageLimit += 30; // Load 30 more
        });
      }
    });


    messageFocusNode.requestFocus();
    dm = Provider.of<DataManager>(context, listen: false);

    dm.signalRService.addOnReceiveMessageListener(handleChatroomMessage);

    dm.signalRService.onReconnected = () {

      var userSession = Hive.box<HiveSession>('sessionBox').get('user');
      dm.signalRService.openChatroom(userSession!.user.userID, widget.chatroomID);
      dm.signalRService.removeOnReceiveMessageListener(handleChatroomMessage);
      dm.signalRService.addOnReceiveMessageListener(handleChatroomMessage);
      dm.signalRService.sendSeen(userSession.user.userID, widget.chatroomID);
    };

    dm.signalRService.onDisconnected = (){
      dm.signalRService.removeOnReceiveMessageListener(handleChatroomMessage);
    };
    dm.enterChatroom(widget.chatroomID);
  }
  @override
  void didChangeDependencies() {

    super.didChangeDependencies();

  }
  @override
  void dispose(){
    dm.signalRService.removeOnReceiveMessageListener(handleChatroomMessage);
    dm.exitChatroom(widget.chatroomID);
    _scrollController.dispose();
    messageFocusNode.dispose();
    super.dispose();
  }


  void handleChatroomMessage(Message message, Chatroom chatroom) {

    var userSession = Hive.box<HiveSession>('sessionBox').get('user');

    if (chatroom.chatroomID == widget.chatroomID) {
      if (!chatroom.messages!.any((msg) => msg.messageID == message.messageID)) {
        if (message.sender.userID != userSession!.user.userID) {
          dm.signalRService.sendSeen(userSession.user.userID, widget.chatroomID);
        } else {
          dm.updateMemberSeen(userSession.user.userID, widget.chatroomID);
        }
        dm.addMessage(message, chatroom);
        setState(() {
          _messageLimit += 1;
        });
      }
    }
  }

  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {

        if (!dataManager.signalRService.isConnected) {

          return DisconnectedOverlay();
        }

        Chatroom chatroom = dataManager.findChatroomByID(widget.chatroomID)!;

        final allMessages = (chatroom.messages ?? []).toList(); // safety if null
        if (allMessages.isEmpty) {
          return const Center(child: CircularProgressIndicator()); // or a 'Loading...' placeholder
        }

        if (_messageLimit > allMessages.length) {
          _messageLimit = allMessages.length; // Clamp to latest available
        }

        final totalMessages = allMessages.length;
        final start = (totalMessages - _messageLimit).clamp(0, totalMessages);
        final end = totalMessages;
        final visibleMessages = allMessages.sublist(start, end).reversed.toList();


        var userSession = Hive.box<HiveSession>('sessionBox').get('user');
        String chatTitle = chatroom.ticket != null ? chatroom.ticket?.ticketTitle ?? "New Chat" : "New Chat";


        dataManager.onRatingUpdate = (rating) {
          enableRate = true;
          TopNotification.show(
              context: context,
              message: "Rating submitted!",
              backgroundColor: Colors.greenAccent,
              duration: Duration(seconds: 2),
              textColor: Colors.white,
              onTap: () {
                TopNotification.dismiss();
              }
          );
        };

        void sendMessage(String messageContent, Chatroom chatroom) {
          if (messageContent.trim().isEmpty) return;

          var userSession = Hive.box<HiveSession>('sessionBox').get('user');
          if (userSession == null) return;

          Provider.of<DataManager>(context, listen: false)
              .signalRService
              .sendMessage(userSession.user.userID, widget.chatroomID, messageContent);

          messageController.clear();

          if (chatroom.ticket == null) {
            setState(() {
              enableMessage = false;
            });
          }else{
            messageFocusNode.requestFocus();
          }

        }
        dataManager.signalRService.onAlreadyMember = (){
          TopNotification.show(
              context: context,
              message: "You are already a member of this group chat!",
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 2),
              textColor: Colors.white,
              onTap: () {
                TopNotification.dismiss();
              }
          );
        };
        dataManager.signalRService.onAllowMessage = () {
          setState(() {
            enableMessage = true;
            messageFocusNode.requestFocus();
          });
        };

        if (chatroom == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Chatroom Not Found")),
            body: const Center(child: Text("Chatroom does not exist or failed to load.")),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: kPrimary,
            title: Text('${chatTitle}'),
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ],
          ),
          endDrawer: ChatroomDetailsDrawer(chatroom: dataManager.findChatroomByID(widget.chatroomID)!, dataManager: dataManager),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Show latest messages at the bottom
                  itemCount: visibleMessages.length,
                  itemBuilder: (context, index) {
                    final message = visibleMessages[index];
                    final previousMessage = index < visibleMessages.length - 1 ? visibleMessages[index + 1] : null;
                    final seenByMembers = chatroom.groupMembers!
                        .where((m) => m.lastSeenAt != null && m.lastSeenAt!.isAfter(message.createdAt))
                        .toList();

                    final isMe = message.sender.userID == userSession!.user.userID;
                    final isSeen = seenByMembers.isNotEmpty && seenMessageID == message.messageID;

                    List<Widget> messageColumn = [];

                    if (shouldShowHourSeparator(message, previousMessage)) {
                      messageColumn.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                TimeUtil.formatTimestamp(message.createdAt),
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    messageColumn.add(
                      Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                seenMessageID = (seenMessageID == message.messageID) ? null : message.messageID;
                              });
                            },
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (previousMessage == null || previousMessage.sender.userID != message.sender.userID)
                                  Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    "${message.sender.firstName}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Tooltip(
                                      message: TimeUtil.formatTimestamp(message.createdAt),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isMe ? kPrimaryContainer : kTertiaryContainer,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        constraints: BoxConstraints(
                                          maxWidth: constraints.maxWidth * 0.5,
                                        ),
                                        child: MarkdownBody(
                                          data: message.messageContent,
                                          styleSheet: MarkdownStyleSheet(
                                            p: const TextStyle(fontSize: 14, color: Colors.black, fontFamilyFallback: [
                                              'Apple Color Emoji',
                                              'Segoe UI Emoji',
                                              'Noto Color Emoji',
                                              'EmojiOne Color',
                                            ]),
                                            strong: const TextStyle(fontWeight: FontWeight.bold),
                                            blockquote: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),

                                          ),
                                          selectable: true,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (isSeen)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2, right: 12, left: 12),
                                    child: Text(
                                      _formatSeenBy(seenByMembers, userSession),
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: messageColumn,
                    );
                  }
                ),
              ),
              if(chatroom.isClosed && chatroom.author.userID == userSession?.user.userID)
                _buildReopenAndRateButtons(dataManager, userSession, chatroom)
              else if (chatroom.isClosed)
                _buildClosedBar(dataManager, userSession, chatroom)
              else if (chatroom.groupMembers!.any((u) => u.member?.userID == userSession?.user.userID))
                _buildMessageInput(chatroom, sendMessage)
              else
                _buildJoinRoomButton(dataManager, userSession, chatroom),
            ],
          ),
        );
      },
    );

  }

  Widget _buildMessageInput(Chatroom chatroom, Function(String message, Chatroom chatroom) sendMessage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              focusNode: messageFocusNode,
              keyboardType: TextInputType.multiline,
              maxLines: 4, // Expands up to 4 lines, then scrolls
              minLines: 1,
              textInputAction: TextInputAction.newline, // Allows multi-line
              enabled: enableMessage,
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
              onEditingComplete: () {
                // Ensures the message is sent when Enter is pressed
                (messageController.text.trim(), chatroom);
                messageController.clear();
                enableMessage = false;
              },
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.endsWith('\n') && !HardwareKeyboard.instance.isShiftPressed) {
                    sendMessage(newValue.text.trim(), chatroom);
                    return TextEditingValue.empty;
                  }
                  return newValue;
                }),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: enableMessage ? Colors.blue : Colors.grey),
            onPressed: enableMessage ? () => sendMessage(messageController.text.trim(), chatroom) : null,
          ),
        ],
      ),
    );
  }
  Widget _buildJoinRoomButton(DataManager dataManager, HiveSession? userSession, Chatroom chatroom) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ElevatedButton(
        onPressed: () {
          if (userSession != null) {
            dataManager.signalRService.joinChatroom(userSession.user.userID, chatroom.chatroomID);
          }
        },
        child: Text("Join Room"),
      ),
    );
  }

  Widget _buildReopenAndRateButtons(DataManager dataManager, HiveSession? userSession, Chatroom chatroom) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if(chatroom.ticket != null)ElevatedButton(
            onPressed: () {
              if (userSession != null && chatroom.ticket?.status == 'Closed') {
                dataManager.signalRService.updateTicket(chatroom.ticket!.ticketID, chatroom.ticket!.ticketTitle, 'Open', chatroom.ticket!.priority, chatroom.ticket!.mainTag?.tagName, chatroom.ticket!.subTag?.subTagName, chatroom.ticket!.assigned?.userID);
              }
            },
            child: const Text("Reopen Chatroom"),
          ),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => RatingDialogWidget(
                  rating: dataManager.findRatingByChatroomID(chatroom.chatroomID),
                  onSubmit: (rating, feedback) {
                    // Handle the rating and feedback submission
                    enableRate = false;
                    dataManager.signalRService.addRating(
                      chatroom.chatroomID,
                      rating,
                      feedback,
                    );

                  },
                ),
              );
            },
            child: const Text("Rate Chatroom"),
          ),
        ],
      ),
    );
  }


  Widget _buildClosedBar(DataManager dataManager, HiveSession? userSession, Chatroom chatroom) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child:  Text("Viewing archived chat"),
    );
  }

  bool shouldShowHourSeparator(Message current, Message? previous) {
    if (previous == null) return true; // First message
    return current.createdAt.difference(previous.createdAt).inMinutes > 90;
  }

  String _formatSeenBy(List<GroupMember> seenBy, HiveSession session) {
    return 'Seen by ${seenBy.map((u) => u.member?.userID == session.user.userID ? 'You' : u.member?.firstName ?? '').join(", ")}';
  }

}
