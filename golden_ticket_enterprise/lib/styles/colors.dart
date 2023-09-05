import 'dart:math';

import 'package:flutter/material.dart' show Color, Colors;

const Color kSurface = Colors.white;
const Color kOnSurface = Color(0xFF1A243B);

const Color kPrimary = Color(0xFFC6A663);
const Color kOnPrimary = Colors.white;

const Color kSecondary = Color(0xFFC1C5CE);
const Color kOnSecondary = Colors.black;

const Color kTertiary = Color(0xFF8385F3);
const Color kOnTertiary = Colors.black;

const Color kError = Color(0xFFDB3A3A);
const Color kOnError = Colors.black;

const Color kPrimaryContainer = Color(0xFFEEDBB2);
const Color kOnPrimaryContainer = Color(0xFF3E2A00);

const Color kSecondaryContainer = Color(0xFFE4E7F0);
const Color kOnSecondaryContainer = Color(0xFF181E2C);

const Color kTertiaryContainer = Color(0xFFC3C9F3);
const Color kOnTertiaryContainer = Color(0xFF1A1742);

const Color kOutline = Color(0xFF838383);
const Color kOutlineVariant = Color(0xFFD9D9D9);

Color getStatusColor(String status){
  switch(status){
    case 'Open':
      return Colors.green;
    case 'In Progress':
      return Colors.lightBlueAccent;
    case 'Postponed':
      return Colors.orangeAccent;
    case 'Closed':
      return Colors.red;
    case 'Unresolved':
      return Colors.redAccent;
  }
  return Colors.black;
}
Color getPriorityColor(String status){
  switch(status){
    case 'High':
      return Colors.redAccent;
    case 'Medium':
      return Colors.orangeAccent;
    case 'Low':
      return Colors.greenAccent;
  }
  return Colors.black;
}

Color generateRandomColor() {
  final Random random = Random();
  Color color;

  do {
    int r = 100 + random.nextInt(130); // 100–229
    int g = 100 + random.nextInt(130);
    int b = 100 + random.nextInt(130);

    // Avoid grayish tones
    bool isGrayish = (r - g).abs() < 20 && (g - b).abs() < 20 && (r - b).abs() < 20;

    // Check brightness to avoid too light or too dark
    int brightness = (r + g + b) ~/ 3;
    bool isTooBright = brightness > 210;
    bool isTooDark = brightness < 140;

    if (!isGrayish && !isTooBright && !isTooDark) {
      color = Color.fromARGB(255, r, g, b);
      break;
    }
  } while (true);

  return color;
}

class LineColor {
  final String name;
  final Color color;

  LineColor({required this.name, required this.color});
}