import 'package:flutter/material.dart';

const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator localhost target
const String socketUrl = 'http://10.0.2.2:3000';

class AppColors {
  static const Color empty = Color(0xFF4CAF50); // Green
  static const Color moderate = Color(0xFFFFC107); // Yellow
  static const Color full = Color(0xFFFF9800); // Orange
  static const Color overcrowded = Color(0xFFF44336); // Red
  static const Color primary = Color(0xFF2196F3);
}

// Simple global tokens for API requests
String? globalToken;
