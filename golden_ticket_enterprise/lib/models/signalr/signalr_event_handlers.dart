import 'package:flutter/foundation.dart';
import 'package:golden_ticket_enterprise/entities/apikey.dart';
import 'package:golden_ticket_enterprise/entities/chatroom.dart';
import 'package:golden_ticket_enterprise/entities/faq.dart';
import 'package:golden_ticket_enterprise/entities/notification.dart' as notif;
import 'package:golden_ticket_enterprise/entities/main_tag.dart';
import 'package:golden_ticket_enterprise/entities/message.dart';
import 'package:golden_ticket_enterprise/entities/rating.dart';
import 'package:golden_ticket_enterprise/entities/ticket.dart';
import 'package:golden_ticket_enterprise/entities/user.dart' as UserDTO;
import 'package:golden_ticket_enterprise/models/class_enums.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart'
as UserSession;
import 'package:golden_ticket_enterprise/models/signalr/signalr_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:signalr_core/signalr_core.dart';

class SignalREventHandler extends ChangeNotifier {
  final SignalRService _service;
  final HubConnection _hubConnection;

  var logger = Logger();

  SignalREventHandler(this._service, this._hubConnection);

  void setupEventHandlers(){
    _hubConnection.on('MaximumChatroom', (arguments) {
      _service.onMaximumChatroom?.call();
      _service.notifyListeners();
    });

    _hubConnection.on('AlreadyMember', (arguments) {
      _service.onAlreadyMember?.call();
      notifyListeners();
    });

    _hubConnection.on('ExistingTag', (arguments) {
      _service.onExistingTag?.call();
      notifyListeners();
    });

    _hubConnection.on('UserExist', (arguments) {
      _service.onRegistrationError?.call();
      notifyListeners();
    });

    _hubConnection.on('UserSeen', (arguments) {
      if (arguments != null) {
        int chatroomID = arguments[0]['chatroomID'];
        int userID = arguments[0]['userID'];

        _service.onSeenUpdate?.call(userID, chatroomID);
        notifyListeners();
      }
    });
    _hubConnection.on('AllowMessage', (arguments) {
      _service.onAllowMessage?.call();
      notifyListeners();
    });
    _hubConnection.on('ReceiveMessages', (arguments) {
      if (arguments != null) {
        var chatroomData = arguments[0]['chatroom'];
        Chatroom chatroom = Chatroom.fromJson(chatroomData);
        _service.onChatroomUpdate?.call(chatroom);
      }
      notifyListeners();
    });

    _hubConnection.on('StaffJoined', (arguments) {
      if (arguments != null) {
        _service.onStaffJoined?.call(UserDTO.User.fromJson(arguments[0]['user']),
            Chatroom.fromJson(arguments[0]['chatroom']));
        notifyListeners();
      }
    });

    _hubConnection.on('RatingReceived', (arguments) {
      if (arguments != null) {
        _service.onRatingUpdate?.call(Rating.fromJson(arguments[0]['rating']));
        notifyListeners();
      }
    });

    _hubConnection.on('APIKeyUpdate', (arguments) {
      if (arguments != null) {
        _service.onAPIKeyUpdate?.call(ApiKey.fromJson(arguments[0]['apikey']));
        notifyListeners();
      }
    });
    _hubConnection.on('APIKeysUpdate', (arguments) {
      if (arguments != null) {
        List<ApiKey> updatedAPIKeys = (arguments[0]['apikeys'] as List)
            .map((apiKey) => ApiKey.fromJson(apiKey))
            .toList();
        print(arguments[0]);
        _service.onAPIKeysUpdate?.call(updatedAPIKeys);
        notifyListeners();
      }
    });

    _hubConnection.on('RatingsReceived', (arguments) {
      if (arguments != null) {
        List<Rating> updatedRatings = (arguments[0]['ratings'] as List)
            .map((rating) => Rating.fromJson(rating))
            .toList();

        _service.onRatingsUpdate?.call(updatedRatings);
        notifyListeners();
      }
    });

    _hubConnection.on('TicketUpdate', (arguments) {
      if (arguments != null) {
        _service.onTicketUpdate?.call(Ticket.fromJson(arguments[0]['ticket']));
        notifyListeners();
      }
    });

    _hubConnection.on('NotificationListReceived', (arguments) {
      if (arguments != null) {
        List<notif.Notification> updatedNotifications = (arguments[0]
        ['notification'] as List)
            .map((notification) => notif.Notification.fromJson(notification))
            .toList();
        _service.onNotificationsUpdate?.call(updatedNotifications);
        notifyListeners();
      }
    });
    _hubConnection.on('TicketClosed', (arguments) {
      if (arguments != null) {
        notifyListeners();
      }
    });

    _hubConnection.on('ReceiveMessage', (arguments) {
      if (arguments != null) {
        final message = Message.fromJson(arguments[0]['message']);
        final chatroom = Chatroom.fromJson(arguments[0]['chatroom']);

        _service.triggerOnReceiveMessage(message, chatroom);
        notifyListeners();
      }
    });

    _hubConnection.on('ReceiveSupport', (arguments) async {
      if (arguments != null) {
        await _service.onChatroomUpdate
            ?.call(Chatroom.fromJson(arguments[0]['chatroom']));
        _service.triggerOnReceiveSupport(Chatroom.fromJson(arguments[0]['chatroom']));
        notifyListeners();
      }
    });

    _hubConnection.on('FAQUpdate', (arguments) {
      if (arguments != null) {
        List<FAQ> updatedFAQs = (arguments[0]['faq'] as List)
            .map((faq) => FAQ.fromJson(faq))
            .toList();

        _service.onFAQUpdate?.call(updatedFAQs);
        notifyListeners();
      }
    });
    _hubConnection.on('ChatroomUpdate', (arguments) {
      if (arguments != null) {
        _service.onChatroomUpdate?.call(Chatroom.fromJson(arguments[0]['chatroom']));
        notifyListeners();
      }
    });
    _hubConnection.on('TagUpdate', (arguments) {
      if (arguments != null) {
        List<MainTag> updatedTags = (arguments[0]['tags'] as List)
            .map((tag) => MainTag.fromJson(tag))
            .toList();
        _service.onTagUpdate?.call(updatedTags);
      }
    });

    _hubConnection.on('UserUpdate', (arguments) {
      if (arguments != null) {
        UserDTO.User user = UserDTO.User.fromJson(arguments[0]['user']);
        _service.triggerUserUpdate(user);
        var userSession =
            Hive.box<UserSession.HiveSession>('sessionBox').get('user')!.user;

        if (user.userID == userSession.userID) {
          userSession.username = user.username;
          userSession.firstName = user.firstName;
          userSession.middleName = user.middleName ?? "";
          userSession.lastName = user.lastName;
          userSession.role = user.role;
        }

        notifyListeners();
      }
    });

    _hubConnection.on('NotificationReceived', (arguments) {
      if (arguments != null) {
        _service.triggerNotification(
            notif.Notification.fromJson(arguments[0]['notification']));
        notifyListeners();
      }
    });
    _hubConnection.on('NotificationListRemoved', (arguments) {
      if (arguments != null) {
        List<int> deletedNotifications = (arguments[0]['notification'] as List)
            .map((notif) => int.parse(notif.toString()))
            .toList();
        _service.onNotificationDeleted?.call(deletedNotifications);
        notifyListeners();
      }
    });
    
    _hubConnection.on('APIKeyRemoved', (arguments) {
      if (arguments != null) {
        _service.onAPIKeyRemoved?.call(arguments[0]['apikey'] as int);
        notifyListeners();
      }
    });

    _hubConnection.on('Online', (arguments) {
      
      if (arguments != null) {
        List<MainTag> updatedTags = (arguments[0]['tags'] as List)
            .map((tag) => MainTag.fromJson(tag))
            .toList();

        List<FAQ> updatedFAQs = (arguments[0]['faq'] as List)
            .map((faq) => FAQ.fromJson(faq))
            .toList();

        List<Chatroom> updatedChatrooms = (arguments[0]['chatrooms'] as List)
            .map((chatroom) => Chatroom.fromJson(chatroom))
            .toList();

        List<Ticket> updatedTickets = (arguments[0]['tickets'] as List)
            .map((ticket) => Ticket.fromJson(ticket))
            .toList();

        List<String> updatedStatus = (arguments[0]['status'] as List)
            .map((status) => status.toString())
            .toList();

        List<UserDTO.User> updatedUsers = (arguments[0]['users'] as List)
            .map((user) => UserDTO.User.fromJson(user))
            .toList();

        List<String> updatedPriorities = (arguments[0]['priorities'] as List)
            .map((priority) => priority.toString())
            .toList();

        List<Rating> updatedRatings = (arguments[0]['ratings'] as List)
            .map((rating) => Rating.fromJson(rating))
            .toList();

        List<notif.Notification> updatedNotifications = (arguments[0]
        ['notifications'] as List)
            .map((notification) => notif.Notification.fromJson(notification))
            .toList();

        List<ApiKey> updatedAPIKeys = (arguments[0]['apikeys'] as List)
            .map((apiKey) => ApiKey.fromJson(apiKey))
            .toList();
        
        _service.onTagUpdate?.call(updatedTags);
        _service.onPriorityUpdate?.call(updatedPriorities);
        _service.onFAQUpdate?.call(updatedFAQs);
        _service.onTicketsUpdate?.call(updatedTickets);
        _service.onStatusUpdate?.call(updatedStatus);
        _service.onUsersUpdate?.call(updatedUsers);
        _service.onChatroomsUpdate?.call(updatedChatrooms);
        _service.onAPIKeysUpdate?.call(updatedAPIKeys);
        _service.onNotificationsUpdate?.call(updatedNotifications);
        _service.onRatingsUpdate?.call(updatedRatings);
      }
    });


    _hubConnection.onclose((error) {
      logger.e("❌ SignalR Connection Closed:",
          error: error.toString().isEmpty ? "None provided" : error.toString());

      _service.updateConnectionState(ConnectionType.disconnected);
      if (_service.shouldReconnect) _service.attemptReconnect(); // ✅ Only retry if allowed
    });

    _hubConnection.onreconnecting((error) {
      logger.e("🔄 Reconnecting... Error:",
          error: error.toString().isEmpty ? "None provided" : error.toString());
      _service.updateConnectionState(ConnectionType.reconnecting);
    });

    _hubConnection.onreconnected((connectionId) async {

      var userSession =
      Hive.box<UserSession.HiveSession>('sessionBox').get('user');
      logger.i("✅ Reconnected: $connectionId");
      _service.retryCount = 0; // Reset retry count on successful reconnection
      _service.updateConnectionState(ConnectionType.connected);
      await _hubConnection.invoke("Online", args: [userSession!.user.userID, userSession.user.role]);
    });


  }

  void updateConnectionState(ConnectionType state) {
    _service.updateConnectionState(state);
    notifyListeners();
  }
}