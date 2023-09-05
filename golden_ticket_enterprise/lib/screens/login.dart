import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_ticket_enterprise/entities/user.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/routes.dart';
import 'package:golden_ticket_enterprise/secret.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:golden_ticket_enterprise/models/http_request.dart' as http;
import 'package:golden_ticket_enterprise/widgets/notification_widget.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true; // This will toggle password visibility
  var logger = Logger();

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      var box = Hive.box<HiveSession>('sessionBox');
      var userSession = box.get('user');

      if (userSession != null) {
        bool isDisabled = await accountDisabled(context, userSession.user.userID);

        if (!isDisabled) {
          logger.i("User session found: ${userSession.user.username}");
          context.go('/hub/dashboard', extra: userSession.user);
        }
      }
    });
  }

  void _login() async {
    try {
      String username = usernameController.text;
      String password = passwordController.text;

      if (username.isEmpty || password.isEmpty) {
        TopNotification.show(
          context: context,
          message: "Fill out all the fields!",
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
          textColor: Colors.black,
          onTap: () {
            TopNotification.dismiss();
          },
        );
        return;
      }

      var url = Uri.http(kBaseURL, kLogin);

      var response = await http.requestJson(
        url,
        method: http.RequestMethod.post,
        body: {
          'username': usernameController.text,
          'password': passwordController.text,
        },
      );

      if (response['status'] == 200) {
        User data = User.fromJson(response['body']['user']);
        var box = Hive.box<HiveSession>('sessionBox');
        box.put('user', HiveSession.fromJson(response['body']));
        context.go('/hub/dashboard', extra: data);
      } else {
        TopNotification.show(
          context: context,
          message: "Login failed: ${response['message']}",
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
          textColor: Colors.white,
          onTap: () {
            TopNotification.dismiss();
          },
        );
      }
    } catch (Exception) {
      TopNotification.show(
        context: context,
        message: "Login failed: Can't connect to webserver",
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 2),
        textColor: Colors.white,
        onTap: () {
          TopNotification.dismiss();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center, // Center of the gradient
            radius: 0.8, // Radius of the gradient
            colors: [kSurface, kPrimary], // Colors of the gradient
            stops: [0.02, 2.0], // Stop points for the colors
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8,
            color: kPrimaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: 320, // Adjust width for web responsiveness
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Golden Ticket",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 20),
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: "Username",
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: _obscurePassword, // Toggle visibility
                      onSubmitted: (val) => _login(),
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword; // Toggle the password visibility
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _login(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding:
                        EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                      ),
                      child: Text("Login", style: TextStyle(fontSize: 16, color: kSurface)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
