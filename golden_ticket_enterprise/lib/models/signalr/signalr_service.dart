import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_ticket_enterprise/entities/apikey.dart';
import 'package:golden_ticket_enterprise/entities/chatroom.dart';
import 'package:golden_ticket_enterprise/entities/faq.dart';
import 'package:golden_ticket_enterprise/entities/notification.dart' as notif;
import 'package:golden_ticket_enterprise/entities/main_tag.dart';
import 'package:golden_ticket_enterprise/entities/message.dart';
import 'package:golden_ticket_enterprise/entities/rating.dart';
import 'package:golden_ticket_enterprise/entities/ticket.dart';
import 'package:golden_ticket_enterprise/entities/user.dart' as UserDTO;
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart'
    as UserSession;
import 'package:golden_ticket_enterprise/models/signalr/signalr_event_handlers.dart';
import 'package:golden_ticket_enterprise/secret.dart';
import 'package:golden_ticket_enterprise/widgets/notification_widget.dart';
import 'package:golden_ticket_enterprise/widgets/ticket_detail_widget.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:golden_ticket_enterprise/models/class_enums.dart';

class SignalRService with ChangeNotifier {
  HubConnection? _hubConnection;
  VoidCallback? onConnected;
  late SignalREventHandler _eventHandlers;

  var logger = Logger();

  final List<void Function(Message, Chatroom)> _onReceiveMessageListeners = [];
  final List<void Function(Chatroom)> _onReceiveSupportListeners = [];
  final List<void Function(notif.Notification)> _onNotificationListener = [];
  final List<void Function(UserDTO.User)> _onUserUpdateListener = [];

  Function(List<String>)? onPriorityUpdate;
  Function(List<MainTag>)? onTagUpdate;
  Function(List<FAQ>)? onFAQUpdate;
  Function(Chatroom)? onChatroomUpdate;
  Function(List<Chatroom>)? onChatroomsUpdate;
  Function(Rating)? onRatingUpdate;
  Function(List<Rating>)? onRatingsUpdate;
  Function(List<Ticket>)? onTicketsUpdate;
  Function(List<ApiKey>)? onAPIKeysUpdate;
  Function(int)? onAPIKeyRemoved;
  Function(ApiKey)? onAPIKeyUpdate;
  Function(Ticket)? onTicketUpdate;
  Function(List<UserDTO.User>)? onUsersUpdate;
  Function(notif.Notification)? onNotificationReceive;
  Function(List<int>)? onNotificationDeleted;
  Function(List<notif.Notification>)? onNotificationsUpdate;
  Function(Chatroom)? onReceiveSupport;
  Function(List<String>)? onStatusUpdate;
  Function(int, int)? onSeenUpdate;
  Function(UserDTO.User, Chatroom)? onStaffJoined;
  Function()? onAllowMessage;
  Function()? onMaximumChatroom;
  Function()? onExistingTag;
  Function()? onAlreadyMember;
  Function()? onAlreadyDeleted;
  Function()? onRegistrationError;
  Function()? onReconnected;
  Function()? onDisconnected;

  ConnectionType _connectionState = ConnectionType.disconnected;
  ConnectionType get connectionState => _connectionState;

  bool get isConnected => _connectionState == ConnectionType.connected;

  final String serverUrl = "http://${kBaseURL}/${kGTHub}";
  int retryCount = 0; // For exponential backoff
  bool shouldReconnect = true; // ✅ Prevents reconnecting after logout

  /// Initializes the SignalR connection
  Future<void> initializeConnection() async {
    _hubConnection = HubConnectionBuilder()
        .withUrl(
          serverUrl,
          // HttpConnectionOptions(logging: (level, message) {
          //   switch(level){
          //     case LogLevel.information:
          //         // logger.i(message);
          //       break;
          //     case LogLevel.trace:
          //       logger.t(message);
          //     case LogLevel.debug:
          //       logger.d(message);
          //     case LogLevel.warning:
          //       logger.w(message);
          //     case LogLevel.error:
          //       logger.e(message, error: "None Provided");
          //     case LogLevel.critical:
          //       logger.f(message);
          //     case LogLevel.none:
          //       logger.d(message);
          //   }
          // }),
        )
        .build();

    _hubConnection!.serverTimeoutInMilliseconds = 30000;
    _hubConnection!.keepAliveIntervalInMilliseconds = 5000;

    _eventHandlers = SignalREventHandler(this, _hubConnection!);
    _setupEventHandlers();
    await startConnection();
  }

  void requestChat(int userID) async {
    await _hubConnection!
        .send(methodName: 'RequestChat', args: [userID]).catchError((err) {
      logger.e("There was an error caught while sending a message",
          error: err.toString().isEmpty ? "None provided" : err.toString());
    });
  }

  void openChatroom(int userID, int chatroomID) async {
    await _hubConnection!
        .send(methodName: 'OpenChatroom', args: [userID, chatroomID]).catchError((err) {
      logger.e("There was an error caught while opening chatroom",
          error: err.toString().isEmpty ? "None provided" : err.toString());
    });
  }

  void addMainTag(String tagName) async {
    await _hubConnection!
        .send(methodName: 'AddMainTag', args: [tagName]).catchError((err) {
      logger.e("There was an error caught while saving main tag",
          error: err.toString().isEmpty ? "None provided" : err.toString());
    });
  }

  void updateTicket(int ticketID, String title, String status, String priority,
      String? mainTag, String? subTag, int? assignedID) async {
    await _hubConnection!.send(methodName: 'UpdateTicket', args: [
      ticketID,
      title,
      status,
      priority,
      mainTag?.isEmpty == true
          ? null
          : mainTag, // Ensure null instead of empty string
      subTag?.isEmpty == true
          ? null
          : subTag, // Ensure null instead of empty string
      assignedID == 0 ? null : assignedID // Ensure null instead of 0
    ]).catchError((err) {
      logger.e("There was an error caught while updating ticket",
          error: err.toString().isEmpty ? "None provided" : err.toString());
    });
  }

  void updateFAQ(
      int faqID,
      String faqTitle,
      String faqDescription,
      String faqSolution,
      String? mainTag,
      String? subTag,
      bool faqArchive) async {
    await _hubConnection!.send(methodName: 'UpdateFAQ', args: [
      faqID,
      faqTitle,
      faqDescription,
      faqSolution, // Ensure null instead of empty string
      mainTag?.isEmpty == true
          ? null
          : mainTag, // Ensure null instead of empty string
      subTag?.isEmpty == true ? null : subTag,
      faqArchive
    ]).catchError((err) {
      logger.e("There was an error caught while updating FAQ",
          error: err.toString().isEmpty ? "None provided" : err.toString());
    });
  }

  void addSubTag(String tagName, String mainTagName) async {
    await _hubConnection!
        .send(methodName: 'AddSubTag', args: [tagName, mainTagName]).catchError((err) {
      logger.e("There was an error caught while sending a message",
          error: err.toString().isEmpty ? "None provided" : err.toString());
    });
  }

  void addRating(int chatroomID, int score, String? feedback) async {
    await _hubConnection!.send(methodName: 'AddOrUpdateRating',
        args: [chatroomID, score, feedback]).catchError((err) {
      logger.e("There was an error caught while saving rating",
          error: err.toString().isEmpty ? "None provided" : err.toString());
    });
  }

  void addFAQ(String title, String description, String solution, String mainTag,
      String subTag) async {
    await _hubConnection!.send(methodName: 'AddFAQ', args: [
      title,
      description,
      solution,
      mainTag,
      subTag
    ]).catchError((err) {
      logger.e("There was an error caught while adding FAQ",
          error: err.toString().isEmpty ? "None provided" : err.toString());
    });
  }

  void joinChatroom(int userID, int chatroomID) async {
    await _hubConnection!
        .send(methodName: 'JoinChatroom', args: [userID, chatroomID]).catchError((err) {
      logger.e("There was an error caught while joining chatroom",
          error: err.toString().isEmpty ? "None provided" : err.toString());
    });
  }

  void markAsRead(List<int> notifications, int userID) async {
    await _hubConnection!.send(methodName: 'ReadNotification',
        args: [notifications, userID]).catchError((err) {
      logger.e("There was an error caught while marking as read",
          error: err.toString().isEmpty ? "None provided" : err.toString());
    });
  }

  void markAsDelete(List<int> notifications, int userID) async {
    await _hubConnection!.send(methodName: 'DeleteNotification',
        args: [notifications, userID]).catchError((err) {
      logger.e("There was an error caught while deleting notification",
          error: err.toString().isEmpty ? "None provided" : err.toString());
    });
  }

  void deleteAPIKey(int apiKey) async {
    await _hubConnection!
        .send(methodName: 'DeleteAPIKey', args: [apiKey]).catchError((err) {
      logger.e("There was an error caught while deleting API Key",
          error: err.toString().isEmpty ? "None provided" : err.toString());
    });
  }

  void updateUser(
      int userID,
      String? username,
      String? password,
      String? firstName,
      String? middleName,
      String? lastName,
      String? role,
      List<String?> assignedTags,
      bool isDisabled) async {
    await _hubConnection!.send(methodName: 'UpdateUser', args: [
      userID,
      username,
      firstName,
      middleName,
      lastName,
      role,
      assignedTags,
      password,
      isDisabled
    ]).catchError((err) {
      logger.e("There was an error caught while updating user",
          error: err.toString().isEmpty ? "None provided" : err.toString());
    });
  }

  void addUser(
      String username,
      String password,
      String firstName,
      String? middleName,
      String lastName,
      String role,
      List<String> assignedTags) async {
    await _hubConnection!.send(methodName: 'AddUser', args: [
      username,
      password,
      firstName,
      middleName,
      lastName,
      role,
      assignedTags
    ]).catchError((err) {
      logger.e("There was an error caught while Add User",
          error: err.toString().isEmpty ? "None provided" : err.toString());
    });
  }

  void addAPIKey(String apiKey, String? notes) async {
    await _hubConnection!
        .send(methodName: 'AddAPIKey', args: [apiKey, notes]).catchError((err) {
      logger.e("There was an error caught while Adding API Key",
          error: err.toString().isEmpty ? "None provided" : err.toString());
    });
  }

  void updateAPIKey(int apiKeyID, String apiKey, String? notes) async {
    await _hubConnection!.send(methodName: 'UpdateAPIKey', args: [
      apiKeyID,
      apiKey,
      notes ?? 'No note provided'
    ]).catchError((err) {
      logger.e("There was an error caught while Updating API Key",
          error: err.toString().isEmpty ? "None provided" : err.toString());
    });
  }

  void sendMessage(int userID, int chatroomID, String messageContent) async {
    await _hubConnection!.send(methodName: 'SendMessage',
        args: [userID, chatroomID, messageContent]).catchError((err) {
      logger.e("There was an error caught while sending a message",
          error: err.toString());
    });
  }

  void closeChatroom(int chatroomID) async {
    await _hubConnection!
        .send(methodName: 'CloseChatroom', args: [chatroomID]).catchError((err) {
      logger.e("There was an error caught while sending close chatroom",
          error: err.toString());
    });
  }

  void sendSeen(int userID, int chatroomID) async {
    await _hubConnection!
        .send(methodName: 'UserSeen', args: [userID, chatroomID]).catchError((err) {
      logger.e("There was an error caught while sending user seen",
          error: err.toString());
    });
  }

  void addOnReceiveMessageListener(void Function(Message, Chatroom) listener) {
    _onReceiveMessageListeners.add(listener);

  }

  void addOnReceiveSupportListener(void Function(Chatroom) listener) {
    _onReceiveSupportListeners.add(listener);
  }

  void addOnNotificationListener(void Function(notif.Notification) listener) {
    _onNotificationListener.add(listener);
  }

  void addOnUserUpdateListener(void Function(UserDTO.User) listener) {
    _onUserUpdateListener.add(listener);
  }

  void removeOnReceiveMessageListener(void Function(Message, Chatroom) listener) {
      _onReceiveMessageListeners.remove(listener);
  }

  void removeOnReceiveSupportListener(void Function(Chatroom) listener) {
    _onReceiveSupportListeners.remove(listener);
  }

  void removeOnNotificationListener(
      void Function(notif.Notification) listener) {
    _onNotificationListener.remove(listener);
  }

  void removeOnUserListener(void Function(UserDTO.User) listener) {
    _onUserUpdateListener.remove(listener);
  }

  void triggerOnReceiveMessage(Message message, Chatroom chatroom) {
    for (var listener in _onReceiveMessageListeners) {
      listener(message, chatroom);
    }
  }

  void triggerOnReceiveSupport(Chatroom chatroom) {
    for (var listener in _onReceiveSupportListeners) {
      listener(chatroom);
    }
  }

  void triggerNotification(notif.Notification notification) {
    for (var listener in _onNotificationListener) {
      listener(notification);
    }
  }

  void triggerUserUpdate(UserDTO.User user) {
    for (var listener in _onUserUpdateListener) {
      listener(user);
    }
  }

  /// Starts the SignalR connection
  Future<void> startConnection() async {
    if (_hubConnection == null) return;

    try {
      shouldReconnect = true; // ✅ Allow reconnects on normal use
      updateConnectionState(ConnectionType.connecting);
      await _hubConnection!
          .start(); // ❌ If the old tab is using the same user ID, it might get disconnected
      logger.i("✅ SignalR Connected!");
      updateConnectionState(ConnectionType.connected);

      onConnected?.call();

      logger.i("🔄 Invoking Online Event...");
      var userSession =
          Hive.box<UserSession.HiveSession>('sessionBox').get('user');
      await _hubConnection!.send(methodName: "Online",
          args: [userSession!.user.userID, userSession!.user.role]);
    } catch (e) {
      logger.e("❌ Error connecting to SignalR:", error: e.toString());
      updateConnectionState(ConnectionType.disconnected);
      if (shouldReconnect) attemptReconnect();
    }
  }

  void _setupEventHandlers() async {
    _eventHandlers.setupEventHandlers();
  }

  /// Attempt to reconnect with exponential backoff
  Future<void> attemptReconnect() async {
    if (!shouldReconnect || _connectionState == ConnectionType.connected)
      return;

    retryCount++;
    if (retryCount > 3) shouldReconnect = false;
    int delay =
        (5 * retryCount).clamp(5, 30); // Delay increases but max 30 sec
    logger.i("🕐 Retrying in $delay seconds... (Attempt: $retryCount)");

    await Future.delayed(Duration(seconds: delay));
    await startConnection();
  }

  /// Manually trigger reconnection
  Future<void> reconnect() async {
    logger.i("🔁 Manual Reconnect Triggered...");
    shouldReconnect = true; // ✅ Ensure manual reconnects are allowed
    retryCount = 0;
    await startConnection();
  }

  /// Stops the SignalR connection and prevents reconnection
  Future<void> stopConnection() async {
    if (_hubConnection != null) {
      shouldReconnect = false;
      log("SignalR: Stopping connection...");
      await _hubConnection!.stop();
      _hubConnection = null; // Ensure it's fully cleared
    }
  }

  /// Updates connection state and notifies listeners
  void updateConnectionState(ConnectionType state) {
    if(state == ConnectionType.disconnected && connectionState == ConnectionType.connected){
      onDisconnected?.call();
    }

    if(state == ConnectionType.connected && connectionState == ConnectionType.connecting){
      onReconnected?.call();
    }
    _connectionState = state;
    notifyListeners();
  }

  /// Dispose method to properly clean up connection
  @override
  void dispose() {
    stopConnection();
    super.dispose();
  }
}

void handleNotificationRedirect(BuildContext context, DataManager dataManager,
    UserSession.HiveSession session, notif.Notification notification) {
  switch (notification.notificationType) {
    case "Chatroom":
      if (dataManager.isInChatroom) Navigator.pop(context);
      Future.microtask(() {
        openChatroom(context, session, dataManager, notification.referenceID!);
      });
      break;
    case "Ticket":
      Ticket? ticket = dataManager.tickets
          .where((t) => t.ticketID == notification.referenceID)
          .firstOrNull;
      if (ticket != null) {
        showDialog(
          context: context,
          builder: (context) => TicketDetailsPopup(
            ticket: ticket,
            onChatPressed: () =>
                handleChat(context, session, dataManager, ticket),
          ),
        );
      } else {
        TopNotification.show(
            context: context,
            message: "Ticket not found",
            backgroundColor: Colors.redAccent);
      }
      break;
  }
  dataManager.signalRService
      .markAsRead([notification.notificationID], session.user.userID);
}

void handleChat(BuildContext context, UserSession.HiveSession session,
    DataManager dataManager, Ticket ticket) {
  try {
    openChatroom(context, session, dataManager,
        dataManager.findChatroomByTicketID(ticket.ticketID)!.chatroomID);
  } catch (err) {
    TopNotification.show(
        context: context,
        message: "Error chatroom could not be found!",
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 2),
        textColor: Colors.white,
        onTap: () {
          TopNotification.dismiss();
        });
  }
}

void openChatroom(BuildContext context, UserSession.HiveSession session,
    DataManager dataManager, int chatroomID) {
  dataManager.chatroomID = chatroomID;
  dataManager.isInChatroom = true;
  context.push('/hub/chatroom/${chatroomID}');
  Future.delayed(Duration(seconds: 2), () {
    dataManager.enableRequestButton();
  });
  dataManager.signalRService.openChatroom(session.user.userID, chatroomID);
}
