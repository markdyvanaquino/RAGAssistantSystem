import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/screens/hub.dart';
import 'package:golden_ticket_enterprise/screens/error.dart';
import 'package:golden_ticket_enterprise/screens/login.dart';
import 'package:golden_ticket_enterprise/screens/chatroom_page.dart';
import 'package:golden_ticket_enterprise/secret.dart';
import 'package:golden_ticket_enterprise/subscreens/chatroom_list_page.dart';
import 'package:golden_ticket_enterprise/subscreens/dashboard_page.dart';
import 'package:golden_ticket_enterprise/models/http_request.dart' as http;
import 'package:golden_ticket_enterprise/subscreens/faq_page.dart';
import 'package:golden_ticket_enterprise/subscreens/reports_page.dart';
import 'package:golden_ticket_enterprise/subscreens/settings_page.dart';
import 'package:golden_ticket_enterprise/subscreens/tickets_page.dart';
import 'package:golden_ticket_enterprise/subscreens/user_management.dart';
import 'package:golden_ticket_enterprise/widgets/notification_widget.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

class AppRoutes {
  static GoRouter getRoutes() {
    return GoRouter(
      initialLocation: Hive.box<HiveSession>('sessionBox').get('user') == null ? '/login' : '/hub/dashboard',
      errorBuilder: (context, state){

        return ErrorPage(
          errorMessage: '404 Page not found!'// You can conditionally render a button in ErrorPage
        );
      },
      routes: [
        GoRoute(path: '/login', builder: (context, state) => LoginPage()),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            final userSession = Hive.box<HiveSession>('sessionBox').get('user');
            if (userSession == null) {
              return const ErrorPage(errorMessage: 'Unauthorized Access');
            }

            return FutureBuilder<bool>(
              future: accountDisabled(context, userSession.user.userID), // Your async check here
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorPage(errorMessage: 'Something went wrong: ${snapshot.error}');
                }

                if (snapshot.data == true) {
                  return const ErrorPage(errorMessage: 'Account disabled');
                }

                return HubPage(
                  session: userSession,
                  child: navigationShell,
                  dataManager: Provider.of<DataManager>(context, listen: false),
                );
              },
            );
          },
          branches: <StatefulShellBranch>[
            StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                    path: '/hub/dashboard',
                    name: "Dashboard",
                    pageBuilder: (context, state) {

                      var userSession = Hive.box<HiveSession>('sessionBox').get('user');

                      if(userSession == null) return NoTransitionPage(key: state.pageKey, child: ErrorPage(errorMessage: 'Unauthorized Access'));

                      return NoTransitionPage(
                          key: state.pageKey,
                          child: DashboardPage(session: userSession)
                      );
                    },
                  ),
                ]
            ),
            StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                      path: '/hub/chatrooms',
                      name: "Chatrooms",
                      pageBuilder: (context, state){
                        var userSession = Hive.box<HiveSession>('sessionBox').get('user');
                        if(userSession == null) return NoTransitionPage(key: state.pageKey, child: ErrorPage(errorMessage: 'Unauthorized Access'));

                        return NoTransitionPage(
                            key: state.pageKey,
                            child: ChatroomListPage(session: userSession)
                        );
                      }
                  ),
                ]
            ),
            StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                      path: '/hub/tickets',
                      name: "Tickets",
                      pageBuilder: (context, state){
                        var userSession = Hive.box<HiveSession>('sessionBox').get('user');
                        if(userSession == null) return NoTransitionPage(key: state.pageKey, child: ErrorPage(errorMessage: 'Unauthorized Access'));

                        return NoTransitionPage(
                            key: state.pageKey,
                            child: TicketsPage(session: userSession)
                        );
                      }
                  )
                ]
            ),
            StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                      path: '/hub/faq',
                      name: "FAQ",
                      pageBuilder: (context, state){
                        var userSession = Hive.box<HiveSession>('sessionBox').get('user');
                        if(userSession == null) return NoTransitionPage(key: state.pageKey, child: ErrorPage(errorMessage: 'Unauthorized Access'));

                        return NoTransitionPage(
                            key: state.pageKey,
                            child: FAQPage(session: userSession)
                        );
                      }
                  )
                ]
            ),
            StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                      path: '/hub/reports',
                      name: "Reports",
                      pageBuilder: (context, state){
                        var userSession = Hive.box<HiveSession>('sessionBox').get('user');
                        if(userSession == null) return NoTransitionPage(key: state.pageKey, child: ErrorPage(errorMessage: 'Unauthorized Access'));

                        return NoTransitionPage(
                            key: state.pageKey,
                            child: ReportsPage(session: userSession)
                        );
                      }
                  )
                ]
            ),
            StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                      path: '/hub/usermanagement',
                      name: "User Management",
                      pageBuilder: (context, state){
                        var userSession = Hive.box<HiveSession>('sessionBox').get('user');
                        if(userSession == null) return NoTransitionPage(key: state.pageKey, child: ErrorPage(errorMessage: 'Unauthorized Access'));

                        return NoTransitionPage(
                            key: state.pageKey,
                            child: UserManagementPage(session: userSession)
                        );
                      }
                  )
                ]
            ),
            StatefulShellBranch(
                routes: <RouteBase>[
                  GoRoute(
                      path: '/hub/settings',
                      name: "Settings",
                      pageBuilder: (context, state){
                        var userSession = Hive.box<HiveSession>('sessionBox').get('user');
                        if(userSession == null) return NoTransitionPage(key: state.pageKey, child: ErrorPage(errorMessage: 'Unauthorized Access'));

                        return NoTransitionPage(
                            key: state.pageKey,
                            child: SettingsPage(session: userSession)
                        );
                      }
                  )
                ]
            )
          ],
        ),
        GoRoute(
          path: '/hub/chatroom/:chatroomID',
          builder: (context, state) {
            final chatroomID = int.tryParse(state.pathParameters['chatroomID']!);
            if (chatroomID == null) {
              return ErrorPage(errorMessage: 'Invalid chatroom ID');
            }
            return ChatroomPage(chatroomID: chatroomID);
          },
        ),
        GoRoute(
          path: '/error',
          builder: (context, state) {
            final errorMessage = state.extra as String? ?? 'An unknown error occurred';
            return ErrorPage(errorMessage: errorMessage);
          },
        ),
      ],
    );
  }
}

Future<bool> accountDisabled(BuildContext context, int userID) async {
    var url = Uri.http(kBaseURL, kValidate);

    var response = await http.requestJson(
        url,
        method: http.RequestMethod.post,
        body: {
          'userID': userID
        }
    );

    if (response['status'] == 200) {
      bool isDisabled = response['body']['isDisabled'];
      if(isDisabled){
        var box = Hive.box<HiveSession>('sessionBox');
        await box.delete('user');
      }
      return isDisabled;
    } else {
      TopNotification.show(
          context: context,
          message: "Login failed: ${response['message']}",
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
          textColor: Colors.white,
          onTap: () {
            TopNotification.dismiss();
          }
      );
      return true;
    }
}