import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:provider/provider.dart';
import 'package:golden_ticket_enterprise/models/class_enums.dart';

class DisconnectedOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector<DataManager, ConnectionType>(
      selector: (_, dataManager) => dataManager.signalRService.connectionState,
      builder: (context, connectionState, child) {
        if (connectionState == ConnectionType.connected) {
          return SizedBox.shrink(); // No overlay when connected
        }

        String statusText;
        bool showRetry = false;

        switch (connectionState) {
          case ConnectionType.connecting:
            statusText = "Connecting to server...";
            break;
          case ConnectionType.reconnecting:
            statusText = "Reconnecting...";
            break;
          case ConnectionType.disconnected:
          default:
            statusText = "Connection lost.";
            showRetry = true;
            break;
        }

        return Stack(
          children: [
            // Glassmorphism Background
            Container(
              color: kSurface.withOpacity(0.6),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: kTertiary.withOpacity(0.2),
              ),
            ),

            // Content
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Loader
                  if (!showRetry)
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.5, end: 1.0),
                      duration: Duration(seconds: 1),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          strokeWidth: 5,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(kPrimary),
                        ),
                      ),
                    ),

                  SizedBox(height: 24),

                  // Connection Status Text with Glow
                  Text(
                    statusText,
                    style: TextStyle(
                      color: Colors.black,
                      decoration: TextDecoration.none,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (showRetry) ...[
                    SizedBox(height: 12),
                    Text(
                      "Please check your connection and try again.",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),

                    // Retry Button with Glow
                    ElevatedButton(
                      onPressed: () {
                        context.read<DataManager>().signalRService.reconnect();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 10,
                        shadowColor: Colors.blueAccent.withOpacity(0.5),
                      ),
                      child: Text(
                        "Retry Now",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none, // 🚨 Forces no underline
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
